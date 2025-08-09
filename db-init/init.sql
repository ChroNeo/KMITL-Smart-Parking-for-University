-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS IOT_Project;

-- Use the newly created or existing database
USE IOT_Project;

-- Drop the User table if it already exists to ensure a clean slate
DROP TABLE IF EXISTS User;

-- Create the User table with the final schema
CREATE TABLE User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'User',
    car_brand VARCHAR(100),
    car_registration VARCHAR(50),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);



-- Insert some dummy data for testing
-- IMPORTANT: Passwords are bcrypt hashes with a salt round of 12.
INSERT INTO User (full_name, phone_number, role, car_brand, car_registration, email, password) VALUES
('Alice Smith', '555-1234', 'Admin', 'Toyota', 'XYZ-123', 'alice.smith@example.com', '$2b$12$4m1Gg8f5M3h9h2o3n6j4s9F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0U1V2W3X4Y5Z6A7B8C9D0E'),
('Bob Johnson', '555-5678', 'User', 'Honda', 'ABC-456', 'bob.johnson@example.com', '$2b$12$5G9F2d8h3k4e6n9j0a2s1f0t8i6u5o4p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2f'),
('Charlie Brown', '555-9012', 'User', 'Ford', 'LMN-789', 'charlie.brown@example.com', '$2b$12$6t3r5e2p9a7s6d4f1g8h0j9k5l3m1n5o4p2q7r3s8t9u0v1w2x3y4z5a6b7c8d9e'),
('Diana Prince', '555-3456', 'Admin', 'Tesla', 'OPQ-012', 'diana.prince@example.com', '$2b$12$3c4x1v8b5n9m7l0k6j3h1g9f8d5s2a7q4w0e9r8t5y6u3i2o1p4a7s8d9f1g2h3j'),
('Ethan Hunt', '555-7890', 'User', 'BMW', 'RST-345', 'ethan.hunt@example.com', '$2b$12$7k8l9j4h1g5f2d6s9a0q1w2e3r4t5y6u7i8o9p0l1k2j3h4g5f6d7s8a9q0w1e2r');
