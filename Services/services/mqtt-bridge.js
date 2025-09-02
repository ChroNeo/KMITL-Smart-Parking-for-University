// services/mqtt-bridge.js
require("dotenv").config();
const Ajv = require("ajv");
const pool = require("./dbconn");
const client = require("./mqttClient");

const BASE = process.env.MQTT_BASE_TOPIC || "univ/parking";

const TOPIC_TELEMETRY = `${BASE}/slots/+/telemetry`;
const topicState = (slot) => `${BASE}/slots/${slot}/state`;
const topicCmd = (slot) => `${BASE}/slots/${slot}/cmd`;

const ajv = new Ajv({ allErrors: true, removeAdditional: true });
const validateTelemetry = ajv.compile({
  type: "object",
  required: ["slot_number", "occupied"],
  additionalProperties: true,
  properties: {
    deviceId: { type: "string" },
    slot_number: { type: "integer", minimum: 1 },
    occupied: { type: "boolean" },
    ts: { type: "string" },
  },
});

function log(...args) {
  console.log("[mqtt-bridge]", ...args);
}

async function withTxn(fn) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (err) {
    try {
      await conn.rollback();
    } catch {}
    throw err;
  } finally {
    conn.release();
  }
}

function publishState(slot, slotName, status) {
  const payload = JSON.stringify({
    slot_number: slot,
    slotId: slotName || `S${slot}`,
    status,
  });
  client.publish(topicState(slot), payload, { qos: 1, retain: true });
  log(`state → ${topicState(slot)} ${payload}`);
}

function publishLED(slot, rgb, reason) {
  const payload = JSON.stringify({
    op: "set_led",
    rgb, // [R,G,B]
    brightness: 255,
    reason,
  });
  client.publish(topicCmd(slot), payload, { qos: 1, retain: false });
  log(`cmd → ${topicCmd(slot)} ${payload}`);
}

async function handleTelemetry(topic, payload) {
  let msg;
  try {
    msg = JSON.parse(payload.toString());
  } catch {
    log("invalid JSON:", payload.toString());
    return;
  }
  if (!validateTelemetry(msg)) {
    log("schema error:", ajv.errorsText(validateTelemetry.errors));
    return;
  }

  const slot = msg.slot_number;
  const wantOccupied = !!msg.occupied;

  const result = await withTxn(async (conn) => {
    const [rows] = await conn.query(
      "SELECT slot_number, slot_name, status FROM Parking_Slots WHERE slot_number = ? FOR UPDATE",
      [slot]
    );
    if (rows.length === 0) throw new Error(`slot ${slot} not found`);
    const curr = rows[0];

    if (curr.status === "DISABLED") {
      // เมิน telemetry แต่ยัง broadcast สถานะกลางไว้
      return { slot, slotName: curr.slot_name, finalStatus: "DISABLED" };
    }

    // หา reservation ที่ยังไม่หมดอายุ
    const [rsv] = await conn.query(
      `SELECT reservation_id, user_id
       FROM Reservation
       WHERE slot_number = ?
         AND reservation_status = 'CONFIRMED'
         AND expires_at > NOW()
       ORDER BY expires_at ASC
       LIMIT 1`,
      [slot]
    );
    const activeResv = rsv[0] || null;

    let finalStatus = curr.status;

    if (wantOccupied) {
      // รถเข้า
      finalStatus = "OCCUPIED";

      await conn.query(
        `INSERT INTO Parking_Data (slot_number, entry_time, user_id)
         SELECT ?, NOW(), ?
         FROM DUAL
         WHERE NOT EXISTS (
           SELECT 1 FROM Parking_Data WHERE slot_number = ? AND out_time IS NULL
         )`,
        [slot, activeResv ? activeResv.user_id : null, slot]
      );

      if (activeResv) {
        await conn.query(
          `UPDATE Reservation
           SET reservation_status='USED', access_verified_at = NOW()
           WHERE reservation_id = ?`,
          [activeResv.reservation_id]
        );
      }

      if (curr.status !== "OCCUPIED") {
        await conn.query(
          `UPDATE Parking_Slots SET status='OCCUPIED' WHERE slot_number=?`,
          [slot]
        );
      }
    } else {
      // รถออก
      await conn.query(
        `UPDATE Parking_Data
         SET out_time = NOW()
         WHERE id = (
           SELECT id FROM (
             SELECT id FROM Parking_Data
             WHERE slot_number = ? AND out_time IS NULL
             ORDER BY id DESC LIMIT 1
           ) t
         )`,
        [slot]
      );

      const [nextR] = await conn.query(
        `SELECT 1 FROM Reservation
         WHERE slot_number = ?
           AND reservation_status='CONFIRMED'
           AND expires_at > NOW()
         LIMIT 1`,
        [slot]
      );

      finalStatus = nextR.length ? "RESERVED" : "FREE";
      if (curr.status !== finalStatus) {
        await conn.query(
          `UPDATE Parking_Slots SET status=? WHERE slot_number=?`,
          [finalStatus, slot]
        );
      }
    }

    return { slot, slotName: curr.slot_name, finalStatus };
  });

  // แจ้งสถานะกลาง (retained)
  publishState(result.slot, result.slotName, result.finalStatus);

  // สั่งไฟตามเงื่อนไขที่เจ้าต้องการ
  switch (result.finalStatus) {
    case "OCCUPIED": // IR trigger → แดง
      publishLED(result.slot, [255, 0, 0], "OCCUPIED");
      break;
    case "RESERVED": // จองอยู่ → เหลือง
      publishLED(result.slot, [255, 255, 0], "RESERVED");
      break;
    case "FREE": // ว่าง → เขียว
      publishLED(result.slot, [0, 255, 0], "FREE");
      break;
    default:
      // DISABLED หรืออื่นๆ ไม่สั่งไฟ
      break;
  }
}

// ─────────────────────────────────────────────────────────────

let started = false;
function onMessage(topic, payload) {
  if (topic.startsWith(`${BASE}/slots/`) && topic.endsWith("/telemetry")) {
    handleTelemetry(topic, payload).catch((e) =>
      log("handle error:", e.message)
    );
  }
}

function ensureSubscribe() {
  if (client.connected) {
    client.subscribe(TOPIC_TELEMETRY, { qos: 1 }, (err) => {
      if (err) log("subscribe error:", err.message);
      else log("subscribed:", TOPIC_TELEMETRY);
    });
  } else {
    client.once("connect", ensureSubscribe);
  }
}

function start() {
  if (started) return;
  started = true;
  ensureSubscribe();
  client.on("message", onMessage);
}

function stop() {
  try {
    client.removeListener("message", onMessage);
    client.unsubscribe(TOPIC_TELEMETRY, () => {});
  } catch {}
  started = false;
}

module.exports = { start, stop };
