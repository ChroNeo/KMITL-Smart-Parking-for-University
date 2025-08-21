# KMITL-Smart-Parking-for-University
Flutter IOT Project KMITL 

# Smart Parking – API TODO List

โครงร่าง API สำหรับระบบ Smart Parking (ESP32 + Node.js + MySQL + MQTT)  

## 1. Auth API
- [ ] `POST /api/v1/login`  
  ตรวจสอบ email + password, คืน JWT  
- [ ] `POST /api/v1/register`  
  สมัครสมาชิกใหม่, hash password (bcrypt)

## 2. Profile API
- [ ] `GET /api/v1/me`  
  ใช้ JWT เพื่อดึงข้อมูล user  
- [ ] `PUT /api/v1/me`  
  แก้ไขข้อมูลโปรไฟล์ของผู้ใช้

## 3. Slots API
- [ ] `GET /api/v1/slots`  
  คืนรายการช่องจอด พร้อมสถานะ (FREE, RESERVED, OCCUPIED, DISABLED)  
- [ ] `GET /api/v1/slots/:id` *(optional)*  
  รายละเอียดของช่องจอดเดียว

## 4. Reservations API
- [ ] `POST /api/v1/reservations`  
  สร้างการจองที่จอด (ตรวจสอบ slot ว่าง → จอง → set `expires_at`)  
- [ ] `GET /api/v1/reservations`  
  ดึงรายการจองของผู้ใช้  
- [ ] `DELETE /api/v1/reservations/:id`  
  ยกเลิกการจอง (update status → CANCELLED)  
- [ ] **Auto-expire**  
  cron job หรือ IoT ตรวจสอบ `expires_at` → อัพเดทสถานะเป็น EXPIRED

## 5. MQTT Integration
- [ ] `POST /api/v1/mqtt/send`  
  Backend publish ข้อมูล (อัปเดตสถานะ slot, ส่งคำสั่งไปยัง ESP32)  
- [ ] `POST /api/v1/mqtt/receive` *(หรือ WebSocket/Callback)*  
  ESP32 ส่งข้อมูล sensor เข้ามา → บันทึกใน `Parking_Data`

## 6. Admin APIs *(optional)*
- [ ] `GET /api/v1/admin/users`  
  รายชื่อผู้ใช้ทั้งหมด  
- [ ] `GET /api/v1/admin/slots/status`  
  Dashboard แสดงสถานะที่จอด

---
**Database Ref:**  
- ตาราง `users`, `Parking_Slots`, `Reservation`, `Parking_Data`  
- ENUM status:  
  - Slot → FREE, RESERVED, OCCUPIED, DISABLED  
  - Reservation → CONFIRMED, CANCELLED, EXPIRED, USED  
