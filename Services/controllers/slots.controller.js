const conn = require("../services/dbconn");

const getStatus = async (req, res) => {
  try {
    const [rows] = await conn.query(`
            SELECT slot_number, slot_name, status
            FROM Parking_Slots
            ORDER BY slot_number ASC
            `);

    res.json({
      count: rows.length,
      items: rows,
    });
  } catch (err) {
    console.error("Error fetching slot status:", err);
    res.status(500).json({ error: "Failed to fetch slot status" });
  }
};
const getSlotDetail = async (req, res) => {
  const { id } = req.params;
  const me = req.user; // มาจาก JWT { id, role, email }

  try {
    if (me.role === "user") {
      // ผู้ใช้ธรรมดา: เห็นเฉพาะ reservation ของตัวเอง
      const [rows] = await conn.query(
        `SELECT reservation_id, slot_number, access_code, created_at, expires_at, reservation_status
         FROM Reservation
         WHERE slot_number = ? AND user_id = ?
         ORDER BY created_at DESC
         LIMIT 1`,
        [id, me.id]
      );
      if (rows.length === 0) {
        return res.status(404).json({ message: "No reservation for this slot by this user" });
      }
      return res.json(rows[0]);
    }

    if (me.role === "admin") {
      // แอดมิน: เห็นครบ ทั้ง slot, reservation ล่าสุด, user, parking_data
      const [rows] = await conn.query(
        `
        SELECT
          s.slot_number, s.slot_name, s.status,
          r.reservation_id, r.access_code, r.created_at, r.expires_at, r.reservation_status,
          u.full_name, u.phone_number, u.email, u.car_registration, u.car_brand, u.car_province,
          pd.entry_time, pd.out_time
        FROM Parking_Slots s
        LEFT JOIN (
          SELECT * FROM Reservation
          WHERE slot_number = ?
          ORDER BY created_at DESC LIMIT 1
        ) r ON r.slot_number = s.slot_number
        LEFT JOIN users u ON u.user_id = r.user_id
        LEFT JOIN (
          SELECT * FROM Parking_Data
          WHERE slot_number = ?
          ORDER BY entry_time DESC LIMIT 1
        ) pd ON pd.slot_number = s.slot_number
        WHERE s.slot_number = ?`,
        [id, id, id]
      );
      if (rows.length === 0) {
        return res.status(404).json({ message: "Slot not found" });
      }
      return res.json(rows[0]);
    }

    return res.status(403).json({ message: "Forbidden" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};
module.exports = { getStatus,getSlotDetail };
