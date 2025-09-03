// controllers/reservation.controller.js
const conn = require("../services/dbconn");
const mqtt = require("../services/mqttClient"); // ← เพิ่ม
const BASE = process.env.MQTT_BASE_TOPIC || "univ/parking"; // ← เพิ่ม
const reservation = async (req, res) => {
  const { slot_number } = req.body;
  const userId = req.user?.id;

  if (!slot_number)
    return res.status(400).json({ message: "slot_number is required" });

  let tx;
  try {
    tx = await conn.getConnection();
    await tx.beginTransaction();

    // ล็อกแถวช่องจอดกันแข่งจอง
    const [slots] = await tx.query(
      "SELECT status, slot_name FROM Parking_Slots WHERE slot_number = ? FOR UPDATE",
      [slot_number]
    );
    if (slots.length === 0) {
      await tx.rollback();
      return res.status(404).json({ message: "Slot not found" });
    }
    if (slots[0].status !== "FREE") {
      await tx.rollback();
      return res.status(400).json({ message: "Slot is not available" });
    }

    // access code แบบตัวเลข 6 หลัก
    const accessCode = Math.floor(100000 + Math.random() * 900000).toString();

    // สร้างการจอง + ตั้งหมดอายุ 60 นาที
    const [ins] = await tx.query(
      `INSERT INTO Reservation (user_id, slot_number, access_code, reservation_status, expires_at)
       VALUES (?, ?, ?, 'CONFIRMED', DATE_ADD(NOW(), INTERVAL 60 MINUTE))`,
      [userId, slot_number, accessCode]
    );

    // อัปเดตสถานะช่องเป็น RESERVED
    await tx.query(
      "UPDATE Parking_Slots SET status = 'RESERVED' WHERE slot_number = ?",
      [slot_number]
    );

    // ดึงค่าที่ DB คำนวณไว้ (created_at, expires_at)
    const [rows] = await tx.query(
      `SELECT reservation_id, slot_number, access_code, reservation_status, created_at, expires_at
         FROM Reservation WHERE reservation_id = ?`,
      [ins.insertId]
    );

    await tx.commit();
    
    const slotName = slots[0].slot_name || `S${slot_number}`;
    const stateTopic = `${BASE}/slots/${slot_number}/state`;
    const cmdTopic = `${BASE}/slots/${slot_number}/cmd`;

    // สถานะกลางให้ retained
    const statePayload = JSON.stringify({
      slot_number,
      slotId: slotName,
      status: "RESERVED",
    });
    mqtt.publish(stateTopic, statePayload, { qos: 1, retain: true }, (e) => {
      if (e) console.error("[mqtt] publish state error:", e.message);
    });

    // คำสั่ง LED ใช้ค่า RGB แบบตัวเลข [R,G,B] ตามที่เจ้าต้องการ
    const ledPayload = JSON.stringify({
      op: "set_led",
      rgb: [255, 255, 0],
      brightness: 255,
      reason: "RESERVED",
    });
    mqtt.publish(cmdTopic, ledPayload, { qos: 1, retain: false }, (e) => {
      if (e) console.error("[mqtt] publish cmd error:", e.message);
    });

    const r = rows[0];
    return res.status(201).json({
      reservation_id: r.reservation_id,
      slot_number: r.slot_number,
      reservation_status: r.reservation_status,
      access_code: r.access_code,
      created_at: new Date(r.created_at).toISOString(),
      expires_at: r.expires_at ? new Date(r.expires_at).toISOString() : null,
    });
  } catch (err) {
    if (tx)
      try {
        await tx.rollback();
      } catch {}
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  } finally {
    if (tx) tx.release();
  }
};
// GET /api/v1/reservations/by-slot/:slot_number
const getReservationBySlot = async (req, res) => {
  const userId = req.user.id; // จาก JWT
  const slotNumber = Number(req.params.slot_number);
  if (!Number.isInteger(slotNumber))
    return res.status(400).json({ message: "slot_number ไม่ถูกต้อง" });

  try {
    // หา reservation ล่าสุดที่ยังแอคทีฟของช่องนี้
    const [rows] = await conn.query(
      `SELECT r.*, s.slot_name, u.full_name, u.car_registration, u.phone_number
       FROM Reservation r
       JOIN Parking_Slots s ON r.slot_number = s.slot_number
       JOIN users u ON r.user_id = u.user_id
       WHERE r.slot_number = ? 
         AND r.reservation_status IN ('CONFIRMED','USED')
         AND r.expires_at > NOW()
       ORDER BY r.created_at DESC
       LIMIT 1`,
      [slotNumber]
    );

    if (rows.length === 0) {
      return res
        .status(404)
        .json({ message: "ยังไม่มีการจองที่ใช้งานสำหรับช่องนี้" });
    }

    const r = rows[0];

    // เจ้าของ หรือ admin เห็นได้เต็ม
    if (r.user_id === userId || req.user.role === "admin") {
      return res.json({
        reservation_id: r.reservation_id,
        slot_number: r.slot_number,
        slot_name: r.slot_name,
        full_name: r.full_name,
        car_registration: r.car_registration,
        access_code: r.access_code,
        access_verified_at: r.access_verified_at,
        created_at: r.created_at,
        expires_at: r.expires_at,
        reservation_status: r.reservation_status,
        phone_number: r.phone_number,
      });
    }

    // คนอื่น: ไม่อนุญาต เห็นแค่ข้อมูลสาธารณะพอประมาณ
    return res.status(403).json({
      message: "ช่องนี้ถูกจองโดยผู้ใช้อื่น",
      slot_number: r.slot_number,
      slot_name: r.slot_name,
      reserved_until: r.expires_at,
      reservation_status: r.reservation_status,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

const getReservation = async (req, res) => {
  const userId = req.user.id;
  try {
    const [rows] = await conn.query(
      `SELECT 
        r.*,
        s.slot_name,
        u.full_name,
        u.car_registration
      FROM Reservation r
      JOIN Parking_Slots s ON r.slot_number = s.slot_number
      JOIN users u ON r.user_id = u.user_id
      WHERE r.user_id = ?
      ;`,
      [userId]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: "Reservation not found" });
    }
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// DELETE /api/v1/reservation/:id
const cancelReservation = async (req, res) => {
  const me = req.user;
  const reservationId = Number(req.params.id);

  if (!Number.isInteger(reservationId)) {
    return res.status(400).json({ message: "Invalid reservation id" });
  }

  let tx;
  try {
    tx = await conn.getConnection();
    await tx.beginTransaction();

    // Lock the reservation row
    const [rRows] = await tx.query(
      `SELECT reservation_id, user_id, slot_number, reservation_status
       FROM Reservation
       WHERE reservation_id = ?
       FOR UPDATE`,
      [reservationId]
    );

    if (rRows.length === 0) {
      await tx.rollback();
      return res.status(404).json({ message: "Reservation not found" });
    }

    const r = rRows[0];

    // Permission: owner or admin only
    if (!(me.role === "admin" || me.id === r.user_id)) {
      await tx.rollback();
      return res.status(403).json({ message: "Forbidden" });
    }

    // Only CONFIRMED can be cancelled
    if (r.reservation_status !== "CONFIRMED") {
      await tx.rollback();
      return res.status(400).json({ message: "Reservation cannot be cancelled" });
    }

    // Cancel the reservation
    await tx.query(
      `UPDATE Reservation
       SET reservation_status = 'CANCELLED'
       WHERE reservation_id = ?`,
      [reservationId]
    );

    // Free the slot only if currently RESERVED
    await tx.query(
      `UPDATE Parking_Slots
       SET status = 'FREE'
       WHERE slot_number = ? AND status = 'RESERVED'`,
      [r.slot_number]
    );

    // Fetch slot info after update
    const [sRows] = await tx.query(
      `SELECT slot_number, slot_name, status FROM Parking_Slots WHERE slot_number = ?`,
      [r.slot_number]
    );

    await tx.commit();

    // Publish MQTT updates to reflect new state
    const slotName = (sRows[0] && sRows[0].slot_name) || `S${r.slot_number}`;
    const currStatus = (sRows[0] && sRows[0].status) || "FREE";
    const stateTopic = `${BASE}/slots/${r.slot_number}/state`;
    const cmdTopic = `${BASE}/slots/${r.slot_number}/cmd`;

    const statePayload = JSON.stringify({
      slot_number: r.slot_number,
      slotId: slotName,
      status: currStatus,
    });
    mqtt.publish(stateTopic, statePayload, { qos: 1, retain: true }, (e) => {
      if (e) console.error("[mqtt] publish state error:", e.message);
    });

    // LED: green if FREE, yellow if RESERVED (unlikely), red if OCCUPIED (no change)
    let rgb = null;
    let reason = currStatus;
    if (currStatus === "FREE") rgb = [0, 255, 0];
    else if (currStatus === "RESERVED") rgb = [255, 255, 0];
    else if (currStatus === "OCCUPIED") rgb = [255, 0, 0];

    if (rgb) {
      const ledPayload = JSON.stringify({ op: "set_led", rgb, brightness: 255, reason });
      mqtt.publish(cmdTopic, ledPayload, { qos: 1, retain: false }, (e) => {
        if (e) console.error("[mqtt] publish cmd error:", e.message);
      });
    }

    return res.json({
      message: "Reservation cancelled",
      reservation_id: reservationId,
      slot_number: r.slot_number,
      status: "CANCELLED",
      slot_status: currStatus,
    });
  } catch (err) {
    if (tx)
      try {
        await tx.rollback();
      } catch {}
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  } finally {
    if (tx) tx.release();
  }
};

module.exports = { reservation, getReservation, getReservationBySlot, cancelReservation };
