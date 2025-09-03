const mqtt = require("mqtt");

const url = process.env.MQTT_URL || "mqtt://localhost:1883";
const client = mqtt.connect(url, {
  clientId: process.env.MQTT_CLIENT_ID || `backend-${Math.random().toString(16).slice(2)}`,
  username: process.env.MQTT_USER,
  password: process.env.MQTT_PASS,
  clean: false,
  keepalive: 60,
  reconnectPeriod: 2000,
});

client.on("connect", () => console.log("[mqtt] connected"));
client.on("error", err => console.error("[mqtt] error:", err.message));

module.exports = client;
