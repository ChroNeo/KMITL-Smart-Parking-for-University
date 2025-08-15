// controllers/reservation.controller.js
const conn = require("../services/dbconn");

const reservation = async (req, res) => {
  const { slot_number } = req.body;
  const userId = req.user?.id;

  if (!slot_number) return res.status(400).json({ message: "slot_number is required" });

  let tx;
  try {
    tx = await conn.getConnection();
    await tx.beginTransaction();

    // ล็อกแถวช่องจอดกันแข่งจอง
    const [slots] = await tx.query(
      "SELECT status FROM Parking_Slots WHERE slot_number = ? FOR UPDATE",
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

    const r = rows[0];
    return res.status(201).json({
      reservation_id: r.reservation_id,
      slot_number: r.slot_number,
      reservation_status: r.reservation_status,
      access_code: r.access_code,
      created_at: new Date(r.created_at).toISOString(),
      expires_at: r.expires_at ? new Date(r.expires_at).toISOString() : null
    });
  } catch (err) {
    if (tx) try { await tx.rollback(); } catch {}
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  } finally {
    if (tx) tx.release();
  }
};

module.exports = { reservation };
