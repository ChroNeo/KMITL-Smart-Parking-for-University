// controllers/auth.controller.js
const bcrypt = require("bcryptjs");
const conn = require("../services/dbconn");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");

function requestId(req) {
  return req.headers["x-request-id"] || crypto.randomUUID();
}

function sendError(res, status, code, message, details = [], reqId) {
  return res.status(status).json({
    error: { code, message, details, request_id: reqId },
  });
}

const login = async (req, res) => {
  const rid = requestId(req);
  const { email, password } = req.body || {};

  // 422 – validation
  if (!email || !password) {
    return sendError(
      res,
      422,
      "validation_failed",
      "Missing required fields.",
      [
        !email ? { field: "email", issue: "required" } : null,
        !password ? { field: "password", issue: "required" } : null,
      ].filter(Boolean),
      rid
    );
  }

  try {
    const [rows] = await conn.query(
      "SELECT user_id, email, role, password_hash FROM users WHERE email = ?",
      [email]
    );

    if (rows.length === 0) {
      return sendError(res, 401, "unauthorized", "User not found.", [], rid);
    }

    const user = rows[0];

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return sendError(res, 401, "unauthorized", "Invalid password.", [], rid);
    }

    if (!process.env.JWT_SECRET) {
      return sendError(
        res,
        500,
        "internal",
        "JWT secret not configured.",
        [],
        rid
      );
    }

    const token = jwt.sign(
      { id: user.user_id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { algorithm: "HS256", expiresIn: "1d" }
    );

    return res.json({
      access_token: token,
      token_type: "Bearer",
      expires_in: 86400, // seconds
      request_id: rid,
    });
  } catch (err) {
    console.error("login error:", err);
    return sendError(res, 500, "internal", "Internal server error.", [], rid);
  }
};

const register = async (req, res) => {
  const rid = requestId(req);
  const {
    email,
    fullname,
    phone_number,
    password,
    car_brand,
    car_registration,
    car_province // <-- add this
  } = req.body || {};

  // 422 – validation
  const missing = [
    !email && { field: "email", issue: "required" },
    !fullname && { field: "fullname", issue: "required" },
    !phone_number && { field: "phone_number", issue: "required" },
    !password && { field: "password", issue: "required" },
    !car_brand && { field: "car_brand", issue: "required" },
    !car_registration && { field: "car_registration", issue: "required" },
    !car_province && { field: "car_province", issue: "required" } // <-- add this
  ].filter(Boolean);

  if (missing.length) {
    return sendError(
      res,
      422,
      "validation_failed",
      "Missing required fields.",
      missing,
      rid
    );
  }

  try {
    const passwordHash = await bcrypt.hash(password, 12);

    const [result] = await conn.query(
      `INSERT INTO users (email, full_name, phone_number, password_hash, car_brand, car_registration, car_province)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [email, fullname, phone_number, passwordHash, car_brand, car_registration, car_province] // <-- add car_province
    );

    if (result.affectedRows !== 1) {
      return sendError(res, 500, "internal", "Failed to create user.", [], rid);
    }

    const [userRows] = await conn.query(
      `SELECT user_id AS id, email, full_name AS fullname, phone_number,
              car_brand, car_registration, car_province, created_at
         FROM users WHERE user_id = ?`,
      [result.insertId]
    );

    return res.status(201).json({
      message: "User registered successfully.",
      data: userRows[0],
      request_id: rid,
    });
  } catch (err) {
    // 409 – duplicate
    if (err && (err.code === "ER_DUP_ENTRY" || err.errno === 1062)) {
      // พยายามเดาว่าชนคอลัมน์ไหนจากข้อความ MySQL
      let field = "unknown";
      const m = /for key 'uniq_users_(\\w+)'/i.exec(err.sqlMessage || "");
      if (m && m[1]) field = m[1];
      return sendError(
        res,
        409,
        "conflict",
        "Duplicate value.",
        [{ field, issue: "unique_violation" }],
        rid
      );
    }
    console.error("register error:", err);
    return sendError(res, 500, "internal", "Internal server error.", [], rid);
  }
};
const getMe = async (req, res) => {
  try {
    const userId = req.user.id; // มาจาก middleware auth ที่ decode JWT แล้ว
    const [rows] = await conn.query(
      "SELECT user_id, full_name, email, role, car_brand, car_registration, car_province, phone_number FROM users WHERE user_id = ?",
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};
const updateMe = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      full_name,
      phone_number,
      car_brand,
      car_registration,
      car_province
    } = req.body;

    await conn.query(
      `UPDATE users 
       SET full_name = ?, phone_number = ?, car_brand = ?, car_registration = ?, car_province = ? 
       WHERE user_id = ?`,
      [full_name, phone_number, car_brand, car_registration, car_province, userId]
    );

    res.json({ message: "Profile updated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};
module.exports = { login, register, getMe, updateMe };
