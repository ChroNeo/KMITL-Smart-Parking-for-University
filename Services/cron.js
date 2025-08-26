import cron from "node-cron";
import conn from "./services/dbconn.js";

console.log("Reservation cron worker started...");

cron.schedule("* * * * *", async () => {
  try {
    console.log("Running expire job:", new Date().toISOString());

    await conn.query(`
      UPDATE Reservation
      SET reservation_status = 'EXPIRED'
      WHERE reservation_status = 'CONFIRMED'
        AND expires_at <= NOW()
    `);

    await conn.query(`
      UPDATE Parking_Slots ps
      JOIN Reservation r
        ON r.slot_number = ps.slot_number
        AND r.reservation_id = (
            SELECT MAX(r2.reservation_id)
            FROM Reservation r2
            WHERE r2.slot_number = ps.slot_number
        )
      SET ps.status = 'FREE'
      WHERE ps.status = 'RESERVED'
        AND r.reservation_status = 'EXPIRED';

    `);
  } catch (err) {
    console.error("Cron job error:", err);
  }
});
