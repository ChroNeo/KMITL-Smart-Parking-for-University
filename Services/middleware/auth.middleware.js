// auth.middleware.js
const jwt = require('jsonwebtoken');

const ROLE_MAP = { 1: 'admin', 0: 'user' }; // normalize once

function auth(req, res, next) {
  // Header names are case-insensitive in Node; use get()
  const authHeader = req.get('authorization') || '';
  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7).trim()
    : authHeader.trim();

  if (!token) return res.status(401).json({ message: 'No token provided' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: ['HS256'], // match what you sign with
    });

    // Normalize role once; don’t mutate original fields that other code may rely on
    const role =
      typeof decoded.role === 'number'
        ? ROLE_MAP[decoded.role] || 'user'
        : decoded.role || 'user';

    req.user = {
      id: decoded.sub ?? decoded.id, // choose one convention: use `sub` when signing
      email: decoded.email,          // include only what you actually need
      role,
      iat: decoded.iat,
      exp: decoded.exp,
    };

    return next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired' });
    }
    return res.status(401).json({ message: 'Invalid token' });
  }
}

module.exports = auth;
