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

module.exports = { getStatus };
