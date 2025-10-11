/* ESP32 Smart Parking – Keypad + LCD + IR + Servo + RGB(PCA9685) + MQTT + Access Flow
 * A = ตกลง, C = เคลียร์, รหัส 6 หลัก
 *
 * MQTT Base = univ/parking
 * Slots topics:
 *   PUB:  BASE/slots/{N}/telemetry   {"slot_number":N,"occupied":true|false,"deviceId":"esp32-A2","ts":""}
 *   SUB:  BASE/slots/{N}/cmd         {"op":"set_led","rgb":[R,G,B],"brightness":255} | {"op":"gate","action":"open|close"}
 *
 * Device topics (per ACL: user = esp32-<ID>):
 *   PUB:  BASE/devices/esp32-<ID>/access   {"deviceId":"esp32-<ID>","access_code":"123456"}
 *   SUB:  BASE/devices/esp32-<ID>/cmd      {"op":"access_reply","decision":"GRANTED|DENIED","slot_number":N,"reason":"..."}
 *   PUB:  BASE/devices/esp32-<ID>/status   "online"/"offline" (retain, LWT)
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

#include <Wire.h>
#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <Adafruit_PWMServoDriver.h>
#include <ESP32Servo.h>

// ====================== WIFI / MQTT CONFIG ======================
const char* WIFI_SSID  = "KMITL-WiFi";
const char* WIFI_PASS  = "";

const char* MQTT_HOST  = "172.16.9.152";
const uint16_t MQTT_PORT = 1883;

// สำคัญ: ให้ตรงกับ ACL แบบ user = esp32-<ID>
const char* MQTT_USER  = "esp32-A2";        // esp32-<ID>
const char* MQTT_PASSW = "SlotA2Pass!";

const char* BASE       = "univ/parking";

WiFiClient   espClient;
PubSubClient mqtt(espClient);

// ====================== APP CONFIG ======================
#define LCD_ADDR 0x27
#define PCA9685_ADDR 0x40
#define I2C_SDA 21
#define I2C_SCL 22

const int SLOTS = 5;

// Keypad 4x4
const byte ROWS = 4, COLS = 4;
char keys[ROWS][COLS] = {
  { '1', '2', '3', 'A' },
  { '4', '5', '6', 'B' },
  { '7', '8', '9', 'C' },
  { '*', '0', '#', 'D' }
};
byte rowPins[ROWS] = {13, 14, 15, 16};
byte colPins[COLS] = {18, 19, 23, 33};

// IR 5 ช่อง (34–39 เป็น input-only)
const int IR_PINS[5] = { 36, 39, 34, 35, 32 };
const bool IR_ACTIVE_LOW = true;  // LOW = มีรถ

// Servo 5 ช่อง
const int SERVO_PINS[5] = { 5, 4, 25, 26, 27 };
const int SERVO_CLOSED_ANGLE = 90;
const int SERVO_OPEN_ANGLE   = 0;

// RGB via PCA9685, R/G/B ต่อเรียงช่องละ 3
const int RGB_R_CH[5] = { 0, 3, 6, 9, 12 };
const int RGB_B_CH[5] = { 1, 4, 7, 10, 13 };
const int RGB_G_CH[5] = { 2, 5, 8, 11, 14 };
const bool RGB_INVERT = false;

const unsigned long OPEN_TIMEOUT_MS          = 15000;
const unsigned long TELEMETRY_HEARTBEAT_MS   = 15000;
const unsigned long ACCESS_REPLY_TIMEOUT_MS  = 5000;

// ================== Objects ==================
LiquidCrystal_I2C lcd(LCD_ADDR, 16, 2);
Adafruit_PWMServoDriver pwm(PCA9685_ADDR);
Servo servos[5];

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

// ================== State ==================
String inputBuf;
bool   servoOpen[5]    = { false, false, false, false, false };
unsigned long openAt[5] = { 0, 0, 0, 0, 0 };
bool   irPrev[5];
bool   slotReserved[5] = { false, false, false, false, false };
bool   gateHold[5]     = { false, false, false, false, false };
unsigned long lastFreeMillis[5] = { 0, 0, 0, 0, 0 };
const unsigned long GATE_CLOSE_DELAY_MS = 10000;
uint16_t currentR[5]   = { 0, 0, 0, 0, 0 };
uint16_t currentG[5]   = { 0, 0, 0, 0, 0 };
uint16_t currentB[5]   = { 0, 0, 0, 0, 0 };
unsigned long lastSummary = 0;
const unsigned long SUMMARY_EVERY_MS = 3000;
unsigned long lastEdgePub[5] = {0,0,0,0,0};

// access flow
bool pendingAccess = false;
unsigned long pendingStart = 0;

// ================== Topics ==================
String topicState(int slot){ return String(BASE)+"/slots/"+slot+"/state"; }
String topicCmd  (int slot){ return String(BASE)+"/slots/"+slot+"/cmd"; }
String topicTele (int slot){ return String(BASE)+"/slots/"+slot+"/telemetry"; }
String topicDevAccess(){ return String(BASE)+"/devices/"+MQTT_USER+"/access"; }
String topicDevCmd()   { return String(BASE)+"/devices/"+MQTT_USER+"/cmd"; }
String topicLwt()      { return String(BASE)+"/devices/"+MQTT_USER+"/status"; }

// ================== HW Helpers ==================
bool irOccupied(int i) {
  int v = digitalRead(IR_PINS[i]);
  return IR_ACTIVE_LOW ? (v == LOW) : (v == HIGH);
}
void setPWM16(int ch, uint16_t val) {
  if (RGB_INVERT) val = 4095 - val;
  pwm.setPWM(ch, 0, val);
}
void setSlotColor(int slot, uint16_t r, uint16_t g, uint16_t b) {
  int i = slot - 1;
  if (i < 0 || i >= SLOTS) return;
  if (currentR[i] == r && currentG[i] == g && currentB[i] == b) return;
  setPWM16(RGB_R_CH[i], r);
  setPWM16(RGB_G_CH[i], g);
  setPWM16(RGB_B_CH[i], b);
  currentR[i] = r;
  currentG[i] = g;
  currentB[i] = b;
}
void colorFREE(int slot)     { setSlotColor(slot, 0, 4095, 0); }
void colorRESERVED(int slot) { setSlotColor(slot, 4095, 4095, 0); }
void colorOCCUPIED(int slot) { setSlotColor(slot, 4095, 0, 0); }

void lcdEnter() {
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print("Enter code :");
  lcd.setCursor(0, 1); lcd.print("______");
}
void lcdShowMasked() {
  lcd.setCursor(0, 1);
  String mask; mask.reserve(6);
  for (size_t i = 0; i < inputBuf.length(); i++) mask += '*';
  while (mask.length() < 6) mask += '_';
  lcd.print(mask);
  for (int i = mask.length(); i < 16; i++) lcd.print(' ');
}

void openServoSlot(int slot) {
  int i = slot - 1;
  if (slot < 1 || slot > SLOTS) return;
  servos[i].write(SERVO_OPEN_ANGLE);
  servoOpen[i] = true;
  openAt[i] = millis();
  Serial.printf("[SERVO] Slot %d OPEN at %lu ms\r\n", slot, openAt[i]);
}
void closeServoSlot(int slot) {
  int i = slot - 1;
  if (slot < 1 || slot > SLOTS) return;
  servos[i].write(SERVO_CLOSED_ANGLE);
  servoOpen[i] = false;
  Serial.printf("[SERVO] Slot %d CLOSE at %lu ms\r\n", slot, millis());
}

// ================== MQTT Helpers ==================
void publishTelemetry(int slot, bool occ){
  StaticJsonDocument<256> doc;
  doc["slot_number"] = slot;
  doc["occupied"]    = occ;
  doc["deviceId"]    = MQTT_USER;
  doc["ts"]          = ""; // ใส่เวลาจริงได้ถ้ามี NTP
  char buf[256]; size_t n = serializeJson(doc, buf);
  mqtt.publish(topicTele(slot).c_str(), buf, n);
}

void applyLedCmd(int slot, int r, int g, int b){
  setSlotColor(slot, map(r,0,255,0,4095), map(g,0,255,0,4095), map(b,0,255,0,4095));
}

int parseSlotFromCmdTopic(const String& topic){
  // topic = BASE/slots/{N}/cmd
  int idx = topic.indexOf("/slots/");
  if (idx < 0) return -1;
  int start = idx + 7;
  int slash = topic.indexOf('/', start);
  if (slash < 0) return -1;
  String num = topic.substring(start, slash);
  return num.toInt();
}

void sendAccessRequest(const String& code){
  StaticJsonDocument<128> doc;
  doc["deviceId"]    = MQTT_USER;
  doc["access_code"] = code;
  char buf[128]; size_t n = serializeJson(doc, buf);
  mqtt.publish(topicDevAccess().c_str(), buf, n);
  Serial.printf("[ACCESS] request sent: code=%s\r\n", code.c_str());
}

// ================== MQTT Callback ==================
void onMqtt(char* ctopic, byte* payload, unsigned int len){
  String topic = String(ctopic);

  // 1) คำสั่งต่อช่อง (ไฟ/ประตู)
  if (topic.endsWith("/cmd") && topic.indexOf("/slots/") != -1){
    StaticJsonDocument<256> doc;
    if (deserializeJson(doc, payload, len)) return;
    int slot = parseSlotFromCmdTopic(topic);
    if (slot < 1 || slot > SLOTS) return;

    const char* op = doc["op"] | "";
    if (strcmp(op,"set_led")==0 && doc["rgb"].is<JsonArray>()){
      int r = doc["rgb"][0] | 0, g = doc["rgb"][1] | 0, b = doc["rgb"][2] | 0;
      applyLedCmd(slot, r, g, b);
      const char* reason = doc["reason"] | "";
      int idx = slot - 1;
      if (idx >= 0 && idx < SLOTS) {
        if (strcmp(reason, "RESERVED") == 0) {
          slotReserved[idx] = true;
          gateHold[idx] = false;
          if (servoOpen[idx]) closeServoSlot(slot);
        } else if (strcmp(reason, "OCCUPIED") == 0) {
          slotReserved[idx] = false;
          gateHold[idx] = true;
          lastFreeMillis[idx] = 0;
        } else if (strcmp(reason, "FREE") == 0 || strcmp(reason, "DISABLED") == 0) {
          slotReserved[idx] = false;
        }
      }
    } else if (strcmp(op,"gate")==0){
      const char* action = doc["action"] | "";
      if (strcmp(action,"open")==0)  openServoSlot(slot);
      if (strcmp(action,"close")==0) closeServoSlot(slot);
    }
    return;
  }

  // 2) คำสั่งระดับอุปกรณ์ (access_reply)
  if (topic == topicDevCmd()){
    StaticJsonDocument<256> doc;
    if (deserializeJson(doc, payload, len)) return;
    const char* op = doc["op"] | "";
    if (strcmp(op,"access_reply")!=0) return;

    const char* decision = doc["decision"] | "DENIED";
    int slot = doc["slot_number"] | -1;
    const char* reason = doc["reason"] | "";

    Serial.printf("[ACCESS] reply: %s, slot=%d, reason=%s\r\n", decision, slot, reason);

    if (String(decision) == "GRANTED" && slot >= 1 && slot <= SLOTS){
      // ถ้าช่องยังว่างให้เปิด แล้วปล่อยให้ backend สั่งสีผ่าน MQTT
      int idx = slot - 1;
      if (!irOccupied(idx)){
        openServoSlot(slot);
        slotReserved[idx] = true;
        gateHold[idx] = true;
        colorRESERVED(slot);
        lcd.setCursor(0, 1);
        lcd.print("Slot "); lcd.print(slot); lcd.print(" opened  ");
      } else {
        colorOCCUPIED(slot);
        lcd.setCursor(0, 1);
        lcd.print("Slot "); lcd.print(slot); lcd.print(" occupied ");
      }
      delay(700);
    } else {
      lcd.setCursor(0, 1); lcd.print("Denied          ");
      delay(900);
    }

    // clear สถานะรอ
    pendingAccess = false;
    inputBuf = "";
    lcdEnter();
  }
}

// ================== MQTT Connect ==================
void ensureMqtt(){
  while(!mqtt.connected()){
    String cid = String(MQTT_USER)+"-"+String((uint32_t)ESP.getEfuseMac(), HEX);
    mqtt.setBufferSize(512);
    if(mqtt.connect(cid.c_str(), MQTT_USER, MQTT_PASSW, topicLwt().c_str(), 1, true, "offline")){
      mqtt.publish(topicLwt().c_str(), "online", true);

      // subscribe คำสั่งอุปกรณ์
      mqtt.subscribe(topicDevCmd().c_str(), 1);

      // subscribe คำสั่งประจำช่อง (อยากใช้ก็ได้ ไม่ใช้ก็ไม่เป็นไร)
      for(int s=1; s<=SLOTS; s++){
        mqtt.subscribe(topicCmd(s).c_str(),   1);
      }
    } else {
      delay(1000);
    }
  }
}

// ================== UI/Access ==================
void handleVerifyOnline() {
  if (inputBuf.length() != 6) {
    lcd.setCursor(0, 1); lcd.print("Invalid len    ");
    Serial.println("[KEYPAD] Invalid length");
    delay(900); inputBuf = ""; lcdEnter(); return;
  }
  if (!mqtt.connected()){
    lcd.setCursor(0, 1); lcd.print("MQTT offline   ");
    delay(900); return;
  }

  // ส่ง access_code ไป backend แล้วรอคำตอบ
  lcd.setCursor(0, 1); lcd.print("Checking...    ");
  sendAccessRequest(inputBuf);

  pendingAccess = true;
  pendingStart  = millis();
}

void tickAccessTimeout(){
  if (pendingAccess && millis() - pendingStart > ACCESS_REPLY_TIMEOUT_MS){
    pendingAccess = false;
    lcd.setCursor(0, 1); lcd.print("Timeout        ");
    Serial.println("[ACCESS] reply timeout");
    delay(900);
    inputBuf = "";
    lcdEnter();
  }
}

// ================== Periodic ==================
void periodicUpdate() {
  for (int i = 0; i < SLOTS; i++) {
    bool occ = irOccupied(i);

    if (occ != irPrev[i]) {
      irPrev[i] = occ;
      Serial.printf("[IR] Slot %d -> %s at %lu ms\r\n", i + 1, occ ? "OCCUPIED" : "FREE", millis());
      lastEdgePub[i] = millis();
      publishTelemetry(i+1, occ);
    }

    if (occ) {
      colorOCCUPIED(i + 1);
      slotReserved[i] = false;
      gateHold[i] = true;
      lastFreeMillis[i] = 0;
    } else if (slotReserved[i]) {
      colorRESERVED(i + 1);
      // keep current gateHold to reflect whether access granted
      lastFreeMillis[i] = millis();
    } else {
      colorFREE(i + 1);
      if (gateHold[i]) {
        if (lastFreeMillis[i] == 0) {
          lastFreeMillis[i] = millis();
        } else if (millis() - lastFreeMillis[i] >= GATE_CLOSE_DELAY_MS) {
          gateHold[i] = false;
        }
      } else {
        lastFreeMillis[i] = 0;
      }
    }

    if (gateHold[i]) {
      if (!servoOpen[i]) openServoSlot(i + 1);
    } else if (servoOpen[i]) {
      closeServoSlot(i + 1);
    }

    if (millis() - lastEdgePub[i] > TELEMETRY_HEARTBEAT_MS) {
      lastEdgePub[i] = millis();
      publishTelemetry(i+1, occ);
    }
  }

  if (millis() - lastSummary > SUMMARY_EVERY_MS) {
    lastSummary = millis();
    Serial.print("[SUMMARY] ");
    for (int i = 0; i < SLOTS; i++) Serial.print(irPrev[i] ? "X" : "_");
    Serial.println();
  }

  tickAccessTimeout();
}

// ================== SETUP & LOOP ==================
void setup() {
  Serial.begin(115200);

  Wire.begin(I2C_SDA, I2C_SCL);
  lcd.init(); lcd.backlight(); lcdEnter();

  for (int i = 0; i < SLOTS; i++) {
    pinMode(IR_PINS[i], INPUT);
    irPrev[i] = irOccupied(i);
  }

  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);
  for (int i = 0; i < SLOTS; i++) {
    servos[i].setPeriodHertz(50);
    servos[i].attach(SERVO_PINS[i], 500, 2500);
    servos[i].write(SERVO_CLOSED_ANGLE);
  }

  pwm.begin();
  pwm.setPWMFreq(1000);
  for (int s = 1; s <= SLOTS; s++) colorFREE(s);

  // Wi-Fi
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("[WIFI] Connecting");
  while (WiFi.status() != WL_CONNECTED) { delay(300); Serial.print("."); }
  Serial.printf("\r\n[WIFI] OK: %s\r\n", WiFi.localIP().toString().c_str());

  // MQTT
  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setCallback(onMqtt);
  ensureMqtt();

  Serial.println("[BOOT] Smart Parking ready");
  for (int i = 0; i < SLOTS; i++)
    Serial.printf("[BOOT] IR Slot %d = %s\r\n", i + 1, irPrev[i] ? "OCCUPIED" : "FREE");
}

void loop() {
  if(!mqtt.connected()) ensureMqtt();
  mqtt.loop();

  char k = keypad.getKey();
  if (k) {
    if (k >= '0' && k <= '9') {
      if (inputBuf.length() < 6) { inputBuf += k; lcdShowMasked(); }
    } else if (k == 'C') {
      inputBuf = ""; lcdEnter(); Serial.println("[KEYPAD] Clear");
    } else if (k == 'A') {
      handleVerifyOnline();
    }
  }

  periodicUpdate();
  delay(10);
}
