require("dotenv").config();
const express = require("express");
const cors = require("cors");
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./swagger.js'); 
const app = express();
require('./services/mqtt-bridge').start();

// routes
const testroutes = require("./routes/test_route.js");
const v1routes = require("./routes/v1_route.js");

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use("/", testroutes);
app.use("/api/v1", v1routes);

module.exports = app;
