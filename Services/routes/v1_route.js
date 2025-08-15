const express = require("express");
const {
  login,
  register,
  getMe,
  updateMe,
} = require("../controllers/auth.controller"); // แก้ registor → register
const { getStatus } = require("../controllers/slots.controller");
const auth = require("../middleware/auth.middleware");
const { reservation } = require("../controllers/reservation.controller");
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
/**
 * @swagger
 * /api/v1/slots/status:
 *   get:
 *     summary: Get status of all parking slots
 *     tags: [Slots]
 *     responses:
 *       200:
 *         description: List of parking slots and their status
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 count:
 *                   type: integer
 *                   example: 10
 *                 items:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       slot_number:
 *                         type: integer
 *                         example: 1
 *                       slot_name:
 *                         type: string
 *                         example: "A1"
 *                       status:
 *                         type: string
 *                         example: "available"
 *       500:
 *         description: Failed to fetch slot status
 */
route.get("/slots/status", getStatus);
route.put("/me", auth, updateMe);
/**
 * @swagger
 * /api/v1/me:
 *   put:
 *     summary: Update current user profile
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               full_name:
 *                 type: string
 *                 example: Alice Smith
 *               phone_number:
 *                 type: string
 *                 example: 555-1234
 *               car_brand:
 *                 type: string
 *                 example: Toyota
 *               car_registration:
 *                 type: string
 *                 example: XYZ-123
 *               car_province:
 *                 type: string
 *                 example: กรุงเทพมหานคร
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Profile updated successfully
 *       401:
 *         description: Unauthorized, missing or invalid token
 *       500:
 *         description: Internal server error
 */
route.get("/me", auth, getMe);
/**
 * @swagger
 * /api/v1/me:
 *   get:
 *     summary: Get current user profile
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile information
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user_id:
 *                   type: integer
 *                   example: 1
 *                 full_name:
 *                   type: string
 *                   example: Alice Smith
 *                 email:
 *                   type: string
 *                   example: alice.smith@example.com
 *                 role:
 *                   type: string
 *                   example: admin
 *                 car_brand:
 *                   type: string
 *                   example: Toyota
 *                 car_registration:
 *                   type: string
 *                   example: XYZ-123
 *                 car_province:
 *                   type: string
 *                   example: กรุงเทพมหานคร
 *                 phone_number:
 *                   type: string
 *                   example: 555-1234
 *       401:
 *         description: Unauthorized, missing or invalid token
 *       500:
 *         description: Internal server error
 */
route.post("/reservation", auth, reservation);
/**
 * @swagger
 * /api/v1/reservation:
 *   post:
 *     summary: Create a parking slot reservation
 *     description: Reserves a specific parking slot for the authenticated user.  
 *       The slot will be locked for 60 minutes unless canceled or expired.  
 *       Requires JWT authentication.
 *     tags:
 *       - Reservations
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - slot_number
 *             properties:
 *               slot_number:
 *                 type: integer
 *                 example: 1
 *                 description: The parking slot number to reserve.
 *     responses:
 *       201:
 *         description: Reservation created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 reservation_id:
 *                   type: integer
 *                   example: 42
 *                 slot_number:
 *                   type: integer
 *                   example: 1
 *                 reservation_status:
 *                   type: string
 *                   enum: [CONFIRMED, CANCELLED, EXPIRED, USED]
 *                   example: CONFIRMED
 *                 access_code:
 *                   type: string
 *                   example: "123456"
 *                 created_at:
 *                   type: string
 *                   format: date-time
 *                   example: "2025-08-15T09:30:00.000Z"
 *                 expires_at:
 *                   type: string
 *                   format: date-time
 *                   example: "2025-08-15T10:30:00.000Z"
 *       400:
 *         description: Invalid request or slot not available
 *       404:
 *         description: Slot not found
 *       500:
 *         description: Server error
 */

module.exports = route;
