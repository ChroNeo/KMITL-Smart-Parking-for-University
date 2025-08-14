-- IOT Project – Users table (production-ready)
-- Notes:
-- 1) Store only bcrypt password hashes (60 chars).
-- 2) ENUM values: 'user' | 'admin'.
-- 3) Unique constraints on email, phone, car_registration.

CREATE DATABASE IF NOT EXISTS `IOT_Project` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `IOT_Project`;

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `user_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `full_name`        VARCHAR(255) NOT NULL,
  `phone_number`     VARCHAR(20),
  `role`             ENUM('user','admin') NOT NULL DEFAULT 'user',
  `car_brand`        VARCHAR(100),
  `car_registration` VARCHAR(50),
  `email`            VARCHAR(255) NOT NULL,
  `password_hash`    VARCHAR(60) NOT NULL, -- bcrypt output length = 60
  `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uniq_users_email` (`email`),
  UNIQUE KEY `uniq_users_phone` (`phone_number`),
  UNIQUE KEY `uniq_users_car_reg` (`car_registration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `Parking_Slots`;

CREATE TABLE `Parking_Slots` (
  `slot_number` INT PRIMARY KEY,
  `slot_name` VARCHAR(50) NOT NULL,
  `status` ENUM('FREE','RESERVED','OCCUPIED','DISABLED') NOT NULL DEFAULT 'FREE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `Parking_Slots` (`slot_number`, `slot_name`, `status`) VALUES
(1, 'A1', 'FREE'),
(2, 'A2', 'FREE'),
(3, 'A3', 'FREE'),
(4, 'B1', 'OCCUPIED'),
(5, 'B2', 'RESERVED'),
(6, 'B3', 'DISABLED');

-- Dummy data (bcrypt 12-round placeholders; length 60)
SET @hash := '$2a$12$JzX0rO30y1pG/bAcjZ7fguiWscUEo1i98z1oAoIUUGaEuRq2zgGX6';

INSERT INTO `users` (full_name, phone_number, role, car_brand, car_registration, email, password_hash) VALUES
('Alice Smith',   '555-1234', 'admin', 'Toyota', 'XYZ-123', 'alice.smith@example.com',   @hash),
('Bob Johnson',   '555-5678', 'user',  'Honda',  'ABC-456', 'bob.johnson@example.com',   @hash),
('Charlie Brown', '555-9012', 'user',  'Ford',   'LMN-789', 'charlie.brown@example.com', @hash),
('Diana Prince',  '555-3456', 'admin', 'Tesla',  'OPQ-012', 'diana.prince@example.com',  @hash),
('Ethan Hunt',    '555-7890', 'user',  'BMW',    'RST-345', 'ethan.hunt@example.com',    @hash);

-- Sanity check
-- SELECT user_id, full_name, role, email, LENGTH(password_hash) AS len FROM users;
-- SELECT * FROM Parking_Slots ORDER BY slot_number;
