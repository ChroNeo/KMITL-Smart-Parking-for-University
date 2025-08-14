const express = require("express");
const { testSys, testAdmin } = require("../controllers/test.controller");
const auth = require("../middleware/auth.middleware");
const route = express.Router();

route.get("/test", testSys);
route.get("/testAuth", auth, testAdmin);

module.exports = route;
