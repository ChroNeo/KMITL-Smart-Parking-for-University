-- IOT Project – Full Schema Initialization
-- Store only bcrypt hashes (60 chars)
-- ENUM constraints per design

CREATE DATABASE IF NOT EXISTS `IOT_Project` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `IOT_Project`;

-- Drop old tables (respect FK dependency order)
DROP TABLE IF EXISTS `Parking_Data`;
DROP TABLE IF EXISTS `Reservation`;
DROP TABLE IF EXISTS `Parking_Slots`;
DROP TABLE IF EXISTS `users`;

-- =========================
-- USERS TABLE
-- =========================
CREATE TABLE `users` (
  `user_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `full_name`        VARCHAR(255) NOT NULL,
  `phone_number`     VARCHAR(20),
  `role`             ENUM('user','admin') NOT NULL DEFAULT 'user',
  `car_brand`        VARCHAR(100),
  `car_registration` VARCHAR(50),
  `car_province`     VARCHAR(100),
  `email`            VARCHAR(255) NOT NULL,
  `password_hash`    VARCHAR(60) NOT NULL,
  `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uniq_users_email` (`email`),
  UNIQUE KEY `uniq_users_phone` (`phone_number`),
  UNIQUE KEY `uniq_users_car_reg` (`car_registration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- PARKING_SLOTS TABLE
-- =========================
CREATE TABLE `Parking_Slots` (
  `slot_number` INT NOT NULL,
  `slot_name`   VARCHAR(50) NOT NULL,
  `status`      ENUM('FREE','RESERVED','OCCUPIED','DISABLED') NOT NULL DEFAULT 'FREE',
  PRIMARY KEY (`slot_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- RESERVATION TABLE
-- =========================
CREATE TABLE `Reservation` (
  `reservation_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`        BIGINT UNSIGNED NOT NULL,
  `slot_number`    INT NOT NULL,
  `access_code`    VARCHAR(20),
  `access_verified_at` DATETIME DEFAULT NULL,
  `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at`     TIMESTAMP NOT NULL,
  `reservation_status` ENUM('CONFIRMED','CANCELLED','EXPIRED','USED') NOT NULL DEFAULT 'CONFIRMED',
  PRIMARY KEY (`reservation_id`),
  CONSTRAINT `fk_reservation_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reservation_slot` FOREIGN KEY (`slot_number`) REFERENCES `Parking_Slots`(`slot_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================
-- PARKING_DATA TABLE
-- =========================
CREATE TABLE `Parking_Data` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `slot_number` INT NOT NULL,
  `entry_time`  DATETIME NOT NULL,
  `out_time`    DATETIME DEFAULT NULL,
  `user_id`     BIGINT UNSIGNED,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_parkingdata_slot` FOREIGN KEY (`slot_number`) REFERENCES `Parking_Slots`(`slot_number`) ON DELETE CASCADE,
  CONSTRAINT `fk_parkingdata_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- DUMMY DATA
-- =========================
-- Dummy bcrypt hash (12 rounds)
SET @hash := '$2a$12$JzX0rO30y1pG/bAcjZ7fguiWscUEo1i98z1oAoIUUGaEuRq2zgGX6';

INSERT INTO `users` (full_name, phone_number, role, car_brand, car_registration, car_province, email, password_hash) VALUES
('Alice Smith',   '555-1234', 'admin', 'Toyota', 'XYZ-123', 'กรุงเทพฯ',    'alice.smith@example.com',   @hash),
('Bob Johnson',   '555-5678', 'user',  'Honda',  'ABC-456', 'เชียงใหม่', 'bob.johnson@example.com',   @hash),
('Charlie Brown', '555-9012', 'user',  'Ford',   'LMN-789', 'ภูเก็ต',     'charlie.brown@example.com', @hash),
('Diana Prince',  '555-3456', 'admin', 'Tesla',  'OPQ-012', 'ขอนแก่น',  'diana.prince@example.com',  @hash),
('Ethan Hunt',    '555-7890', 'user',  'BMW',    'RST-345', 'ชลบุรี',   'ethan.hunt@example.com',    @hash);

INSERT INTO `Parking_Slots` (`slot_number`, `slot_name`, `status`) VALUES
(1, 'A1', 'FREE'),
(2, 'A2', 'FREE'),
(3, 'A3', 'FREE'),
(4, 'B1', 'OCCUPIED'),
(5, 'B2', 'RESERVED'),
(6, 'B3', 'DISABLED');

-- Example Reservation
INSERT INTO `Reservation` (user_id, slot_number, access_code, reservation_status, expires_at)
VALUES (2, 1, 'ABC123', 'CONFIRMED', DATE_ADD(NOW(), INTERVAL 60 MINUTE));

-- Example Parking_Data
INSERT INTO `Parking_Data` (slot_number, entry_time, user_id)
VALUES (4, '2025-08-14 09:00:00', 3);

-- Sanity checks:
-- SELECT * FROM users;
-- SELECT * FROM Parking_Slots;
-- SELECT * FROM Reservation;
-- SELECT * FROM Parking_Data;
