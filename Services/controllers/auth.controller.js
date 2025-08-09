const bcrypt = require("bcryptjs");
const conn = require("../services/dbconn");
const jwt = require("jsonwebtoken");
require("dotenv").config();

const login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const [rows] = await conn.query("SELECT * FROM users WHERE email = ?", [
      email,
    ]);

    if (rows.length === 0) {
      console.log("User not found!");
      return res.status(401).json({ error: "User not found!" });
    }

    const user = rows[0];
    console.log(user);
    if (!password || !user.password) {
      console.log("Password is undefined!");
      return res.status(401).json({ error: "Invalid credentials!" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      console.log("Invalid password!");
      return res.status(401).json({ error: "Invalid password!" });
    }

    const token = jwt.sign(
      { id: user.user_id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );
    res.json({
      access_token: token,
      token_type: "Bearer",
      expires_in: "1d",
    });
  } catch (error) {
    console.error("Server error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
const register = async (req, res) => {
  const {
    email,
    fullname,
    phone_number,
    password,
    car_brand,
    car_registration,
  } = req.body;

  if (
    !email ||
    !fullname ||
    !phone_number ||
    !password ||
    !car_brand ||
    !car_registration
  ) {
    return res.status(400).json({ error: "All fields are required!" });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 12);

    const [result] = await conn.query(
      "INSERT INTO users (email,full_name,phone_number,password_hash,car_brand,car_registration) VALUES (?, ?, ?, ?, ?, ?)",
      [
        email,
        fullname,
        phone_number,
        hashedPassword,
        car_brand,
        car_registration,
      ]
    );

    if (result.affectedRows === 1) {
      const [userRows] = await conn.query(
        "SELECT user_id AS id, email, full_name AS fullname, phone_number, car_brand, car_registration, created_at FROM users WHERE user_id = ?",
        [result.insertId]
      );
      const user = userRows[0];
      res
        .status(201)
        .json({ message: "User registered successfully!", data: user });
      return;
    }

    if (result.affectedRows === 1) {
      res
        .status(201)
        .json({ message: "User registered successfully!", data: result });
    } else {
      res.status(500).json({ error: "Failed to register user!" });
    }
  } catch (error) {
    console.error("Server error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
module.exports = { login, register };
