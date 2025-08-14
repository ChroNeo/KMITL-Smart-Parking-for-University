const express = require("express");
const { login, register } = require("../controllers/auth.controller"); // แก้ registor → register
const { getStatus } = require("../controllers/slots.controller");
const route = express.Router();

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: User authentication and registration
 */

/**
 * @swagger
 * /api/v1/login:
 *   post:
 *     summary: User login
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: User's email address
 *               password:
 *                 type: string
 *                 format: password
 *                 description: User's password
 *     responses:
 *       200:
 *         description: Login successful. Returns a JWT token.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Login successful!
 *                 token:
 *                   type: string
 *                   description: JSON Web Token for authentication
 *       401:
 *         description: Invalid credentials
 *       500:
 *         description: Internal server error
 */
route.post("/login", login);

/**
 * @swagger
 * /api/v1/register:
 *   post:
 *     summary: User registration
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - fullname
 *               - phone_number
 *               - password
 *               - car_brand
 *               - car_registration
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: User's email address
 *               fullname:
 *                 type: string
 *                 description: User's full name
 *               phone_number:
 *                 type: string
 *                 description: User's phone number
 *               password:
 *                 type: string
 *                 format: password
 *                 description: User's password
 *               car_brand:
 *                 type: string
 *                 description: Brand of the user's car
 *               car_registration:
 *                 type: string
 *                 description: Registration number of the user's car
 *     responses:
 *       201:
 *         description: User registered successfully.
 *       400:
 *         description: All fields are required.
 *       500:
 *         description: Internal server error.
 */
route.post("/register", register);
route.get("/slots/status", getStatus);
module.exports = route;
