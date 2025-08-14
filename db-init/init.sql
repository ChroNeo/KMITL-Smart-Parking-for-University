-- IOT Project – Users table (reviewed & corrected)
-- Notes:
-- 1) Use password_hash (bcrypt, 60 chars). Do NOT store raw password.
-- 2) ENUM values are lowercase: 'user' | 'admin'.
-- 3) Sample hashes below are 60‑char bcrypt placeholders for testing.

-- Create DB if not exists
CREATE DATABASE IF NOT EXISTS `IOT_Project` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `IOT_Project`;

-- Clean slate
DROP TABLE IF EXISTS `users`;

-- Create table
CREATE TABLE `users` (
  `user_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `full_name`        VARCHAR(255) NOT NULL,
  `phone_number`     VARCHAR(20),
  `role`             ENUM('user','admin') NOT NULL DEFAULT 'user',
  `car_brand`        VARCHAR(100),
  `car_registration` VARCHAR(50),
  `email`            VARCHAR(255) NOT NULL,
  `password_hash`    CHAR(60) NOT NULL,               -- bcrypt output length = 60
  `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uniq_users_email` (`email`),
  UNIQUE KEY `uniq_users_phone` (`phone_number`),      -- remove if duplicates allowed
  UNIQUE KEY `uniq_users_car_reg` (`car_registration`) -- remove if duplicates allowed
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dummy data (bcrypt 12-round placeholders; length 60)
-- Example bcrypt from docs (do not use in production)
SET @hash := '$2b$12$C6UzMDM.H6dfI/f/IKcEe.CyW8Y0ruzJ1j7rwhhtjfiw2BC5T9Nee';

INSERT INTO `users` (full_name, phone_number, role, car_brand, car_registration, email, password_hash) VALUES
('Alice Smith',   '555-1234', 'admin', 'Toyota', 'XYZ-123', 'alice.smith@example.com',   @hash),
('Bob Johnson',   '555-5678', 'user',  'Honda',  'ABC-456', 'bob.johnson@example.com',   @hash),
('Charlie Brown', '555-9012', 'user',  'Ford',   'LMN-789', 'charlie.brown@example.com', @hash),
('Diana Prince',  '555-3456', 'admin', 'Tesla',  'OPQ-012', 'diana.prince@example.com',  @hash),
('Ethan Hunt',    '555-7890', 'user',  'BMW',    'RST-345', 'ethan.hunt@example.com',    @hash);

-- Quick sanity checks
-- SELECT user_id, full_name, role, email, LENGTH(password_hash) AS len FROM users;
