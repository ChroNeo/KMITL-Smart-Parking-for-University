const pool = require("./dbconn");

// ดึงข้อมูลจำนวนการเข้าใช้รถรายวัน
async function queryDailyTraffic(from, to) {
  const [rows] = await pool.query(
    `
    SELECT DATE(entry_time) AS day, COUNT(*) AS total
    FROM Parking_Data
    WHERE entry_time BETWEEN ? AND ?
    GROUP BY DATE(entry_time)
    ORDER BY day ASC
    `,
    [from, to]
  );
  return rows;
}

// ดึงการใช้งานต่อช่องจอด
async function querySlotUsage(from, to) {
  const [rows] = await pool.query(
    `
    SELECT 
      ps.slot_number,
      ps.slot_name,
      ps.status,
      COUNT(pd.id) AS cars
    FROM Parking_Slots ps
    LEFT JOIN Parking_Data pd
      ON pd.slot_number = ps.slot_number
     AND pd.entry_time BETWEEN ? AND ?
    GROUP BY ps.slot_number, ps.slot_name, ps.status
    ORDER BY ps.slot_number ASC
    `,
    [from, to]
  );
  return rows;
}

// ช่วงวันที่มีข้อมูลทั้งหมดใน Parking_Data
async function queryDateRange() {
  const [rows] = await pool.query(
    `
    SELECT MIN(DATE(entry_time)) AS min_day,
           MAX(DATE(entry_time)) AS max_day
    FROM Parking_Data
    `
  );
  return rows && rows[0] ? rows[0] : { min_day: null, max_day: null };
}

module.exports = { queryDailyTraffic, querySlotUsage, queryDateRange };
