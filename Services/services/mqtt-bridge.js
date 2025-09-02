// services/mqtt-bridge.js
require('dotenv').config();
const mqtt = require('mqtt');
const Ajv = require('ajv');

// ปรับ path ให้ตรงกับไฟล์ pool ของเจ้า
const pool = require('./dbconn');

const BASE = process.env.MQTT_BASE_TOPIC || 'univ/parking';
const MQTT_URL = process.env.MQTT_URL || 'mqtt://localhost:1883';
const MQTT_USER = process.env.MQTT_USER;
const MQTT_PASS = process.env.MQTT_PASS;
const CLIENT_ID = process.env.MQTT_CLIENT_ID || `backend-${Math.random().toString(16).slice(2)}`;

const TOPIC_TELEMETRY = `${BASE}/slots/+/telemetry`;
const topicState = (slot) => `${BASE}/slots/${slot}/state`;
const topicDeviceStatus = (id) => `${BASE}/devices/${id}/status`;

const ajv = new Ajv({ allErrors: true, removeAdditional: true });
const validateTelemetry = ajv.compile({
  type: 'object',
  required: ['slot_number', 'occupied'],
  additionalProperties: true,
  properties: {
    deviceId: { type: 'string' },
    slot_number: { type: 'integer', minimum: 1 },
    occupied: { type: 'boolean' },
    ts: { type: 'string' }
  }
});

function log(...args) {
  console.log('[mqtt-bridge]', ...args);
}

async function withTxn(fn) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (err) {
    try { await conn.rollback(); } catch {}
    throw err;
  } finally {
    conn.release();
  }
}

async function handleTelemetry(topic, payload) {
  let msg;
  try {
    msg = JSON.parse(payload.toString());
  } catch {
    log('invalid JSON:', payload.toString());
    return;
  }
  if (!validateTelemetry(msg)) {
    log('schema error:', ajv.errorsText(validateTelemetry.errors));
    return;
  }

  const slot = msg.slot_number;
  const wantOccupied = !!msg.occupied;

  // ดำเนินการแบบ atomic
  const result = await withTxn(async (conn) => {
    // อ่านสถานะปัจจุบัน
    const [rows] = await conn.query(
      'SELECT slot_number, slot_name, status FROM Parking_Slots WHERE slot_number = ? FOR UPDATE',
      [slot]
    );
    if (rows.length === 0) throw new Error(`slot ${slot} not found`);
    const curr = rows[0];

    // ช่องถูกปิดใช้งาน เมิน
    if (curr.status === 'DISABLED') {
      return { slot, slotName: curr.slot_name, finalStatus: 'DISABLED' };
    }

    // หา reservation ที่ยังไม่หมดอายุ
    const [rsv] = await conn.query(
      `SELECT reservation_id, user_id
       FROM Reservation
       WHERE slot_number = ? AND reservation_status = 'CONFIRMED' AND expires_at > NOW()
       ORDER BY expires_at ASC LIMIT 1`,
      [slot]
    );
    const activeResv = rsv[0] || null;

    let finalStatus = curr.status;
    if (wantOccupied) {
      // รถเข้า
      finalStatus = 'OCCUPIED';

      // เปิดประวัติการจอด (ถ้ายังไม่มีแถวเปิดอยู่)
      await conn.query(
        `INSERT INTO Parking_Data (slot_number, entry_time, user_id)
         SELECT ?, NOW(), ?
         FROM DUAL
         WHERE NOT EXISTS (
           SELECT 1 FROM Parking_Data WHERE slot_number = ? AND out_time IS NULL
         )`,
        [slot, activeResv ? activeResv.user_id : null, slot]
      );

      // หากมีการจองที่ยังสด ให้ mark USED
      if (activeResv) {
        await conn.query(
          `UPDATE Reservation
           SET reservation_status='USED', access_verified_at = NOW()
           WHERE reservation_id = ?`,
          [activeResv.reservation_id]
        );
      }

      // ตั้งสถานะสล็อต
      if (curr.status !== 'OCCUPIED') {
        await conn.query(
          `UPDATE Parking_Slots SET status='OCCUPIED' WHERE slot_number=?`,
          [slot]
        );
      }
    } else {
      // รถออก
      // ปิดแถวล่าสุด
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

      // มีการจองถัดไปหรือไม่
      const [nextR] = await conn.query(
        `SELECT 1 FROM Reservation
         WHERE slot_number = ? AND reservation_status='CONFIRMED' AND expires_at > NOW()
         LIMIT 1`,
        [slot]
      );

      finalStatus = nextR.length ? 'RESERVED' : 'FREE';
      if (curr.status !== finalStatus) {
        await conn.query(
          `UPDATE Parking_Slots SET status=? WHERE slot_number=?`,
          [finalStatus, slot]
        );
      }
    }

    return { slot, slotName: curr.slot_name, finalStatus };
  });

  // แจ้งสถานะกลางกลับ (retained)
  const statePayload = JSON.stringify({
    slotId: result.slotName || `S${result.slot}`,
    status: result.finalStatus
  });
  client.publish(topicState(slot), statePayload, { qos: 1, retain: true });
  log(`state → ${topicState(slot)} ${statePayload}`);
}

// ─────────────────────────────────────────────────────────────

let client;

function start() {
  client = mqtt.connect(MQTT_URL, {
    username: MQTT_USER,
    password: MQTT_PASS,
    clientId: CLIENT_ID,
    clean: false,
    keepalive: 60,
    reconnectPeriod: 2000,
    will: { topic: topicDeviceStatus(CLIENT_ID), payload: 'offline', qos: 1, retain: true }
  });

  client.on('connect', () => {
    log('connected to broker');
    client.publish(topicDeviceStatus(CLIENT_ID), 'online', { qos: 1, retain: true });
    client.subscribe(TOPIC_TELEMETRY, { qos: 1 }, (err) => {
      if (err) log('subscribe error:', err.message);
      else log('subscribed:', TOPIC_TELEMETRY);
    });
  });

  client.on('message', (topic, payload) => {
    if (topic.startsWith(`${BASE}/slots/`) && topic.endsWith('/telemetry')) {
      handleTelemetry(topic, payload).catch((e) => log('handle error:', e.message));
    }
  });

  client.on('reconnect', () => log('reconnecting...'));
  client.on('close', () => log('connection closed'));
  client.on('error', (err) => log('mqtt error:', err.message));
}

function stop() {
  try { client && client.end(true); } catch {}
}

module.exports = { start, stop };
