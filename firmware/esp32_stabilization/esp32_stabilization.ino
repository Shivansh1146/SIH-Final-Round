/**
 * ============================================================================
 * SHAYAK-AI: Kinematic Active Stabilization & Tremor Extraction System
 * Target Platform: ESP32 Dual-Core Xtensa LX6 (Arduino Core / ESP-IDF FreeRTOS)
 * Sensor: MPU6050 / MPU9250 6-DOF IMU via Fast I2C (400 kHz)
 * 
 * Physics Constraints:
 * Active counter-thrust PID to negate gravitational acceleration (g = 9.81 m/s^2)
 * along the inertial vertical axis such that F_net = 0.
 * 
 * FreeRTOS Dual-Core Architecture:
 * - Core 0: Hard real-time 100 Hz sensor acquisition, fusion, and PID control loop
 * - Core 1: BLE GATT server advertising & non-blocking telemetry notification
 * ============================================================================
 */

#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>

// ----------------------------------------------------------------------------
// PIN DEFINITIONS & HARDWARE CONSTANTS
// ----------------------------------------------------------------------------
#define I2C_SDA_PIN          21
#define I2C_SCL_PIN          22
#define I2C_CLOCK_SPEED      400000UL // 400 kHz Fast Mode
#define MPU_ADDR             0x68     // MPU6050 / MPU9250 default I2C address

// PWM Actuator Output Pins for Counter-Thrust Vectors (Z-axis + Pitch/Roll balance)
#define THRUST_PWM_PIN_Z     18
#define THRUST_PWM_PIN_PITCH 19
#define THRUST_PWM_PIN_ROLL  23

#define PWM_FREQ_HZ          20000    // 20 kHz ultrasonic PWM to prevent motor whine
#define PWM_RESOLUTION_BITS  10       // 10-bit resolution (0 - 1023)
#define PWM_MAX_DUTY         1023
#define PWM_CHANNEL_Z        0
#define PWM_CHANNEL_PITCH    1
#define PWM_CHANNEL_ROLL     2

// ----------------------------------------------------------------------------
// SENSOR SCALING & PHYSICAL CONSTANTS
// ----------------------------------------------------------------------------
#define GRAVITY_MS2          9.80665f
#define ACCEL_SCALE_2G       16384.0f // LSB/g for +/-2g range
#define GYRO_SCALE_250DPS    131.0f   // LSB/(deg/s) for +/-250 deg/s
#define CONTROL_FREQ_HZ      100      // 100 Hz Control Loop
#define DT_SEC               (1.0f / (float)CONTROL_FREQ_HZ)

// Complementary filter weight (0.98 gyro integration, 0.02 accel vector)
#define FILTER_ALPHA         0.98f

// Tremor sliding window size (100 Hz -> 50 samples = 500 ms window)
#define TREMOR_WINDOW_SIZE   50

// ----------------------------------------------------------------------------
// BLE GATT SERVICE & CHARACTERISTIC UUIDs
// ----------------------------------------------------------------------------
#define SHAYAK_SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define TELEMETRY_CHAR_UUID        "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CONTROL_CHAR_UUID          "1c95d5e3-d7a9-4e4b-9fb5-ea07361b26a9"

// Telemetry binary packet structure streamed to Flutter client
#pragma pack(push, 1)
struct TelemetryPacket {
    float roll_deg;             // Orientation Roll (-180 to +180)
    float pitch_deg;            // Orientation Pitch (-90 to +90)
    float yaw_deg;              // Orientation Yaw (0 to 360)
    float vertical_accel_ms2;   // Inertial earth-frame vertical acceleration
    float net_force_error_n;    // Net force error F_net along vertical axis
    float tremor_variance;      // Micro-jitter variance (4-12 Hz tremor biomarker)
    uint16_t thrust_pwm_z;      // Active PWM duty cycle on counter-thrust
    uint32_t timestamp_ms;      // Monotonic system timestamp
};
#pragma pack(pop)

// ----------------------------------------------------------------------------
// PID CONTROLLER DATA STRUCTURE
// ----------------------------------------------------------------------------
struct PIDController {
    float kp;
    float ki;
    float kd;
    float integral;
    float prev_error;
    float integral_limit;
    float output_min;
    float output_max;

    void init(float p, float i, float d, float int_limit, float out_min, float out_max) {
        kp = p;
        ki = i;
        kd = d;
        integral = 0.0f;
        prev_error = 0.0f;
        integral_limit = int_limit;
        output_min = out_min;
        output_max = out_max;
    }

    float compute(float target, float current, float dt) {
        float error = target - current;
        integral += error * dt;

        // Anti-windup clamping
        if (integral > integral_limit) integral = integral_limit;
        else if (integral < -integral_limit) integral = -integral_limit;

        float derivative = (error - prev_error) / dt;
        prev_error = error;

        float output = (kp * error) + (ki * integral) + (kd * derivative);

        // Output saturation
        if (output > output_max) output = output_max;
        else if (output < output_min) output = output_min;

        return output;
    }

    void reset() {
        integral = 0.0f;
        prev_error = 0.0f;
    }
};

// ----------------------------------------------------------------------------
// GLOBAL INSTANCES & RTOS SYNCHRONIZATION
// ----------------------------------------------------------------------------
QueueHandle_t telemetryQueue;
BLEServer* pServer = nullptr;
BLECharacteristic* pTelemetryChar = nullptr;
BLECharacteristic* pControlChar = nullptr;
bool bleClientConnected = false;

// Kinematic states
float roll = 0.0f;
float pitch = 0.0f;
float yaw = 0.0f;

// Tremor analysis circular buffer
float tremorAccelBuffer[TREMOR_WINDOW_SIZE];
int tremorBufferIndex = 0;
float tremorFilteredVar = 0.0f;

// Mass of stabilized platform in kilograms (e.g. 0.25 kg utensil / stabilizer payload)
const float PLATFORM_MASS_KG = 0.25f;

// Feedforward base PWM to counteract gravity at rest (mg = Base Thrust)
const float BASE_GRAVITY_PWM = (PLATFORM_MASS_KG * GRAVITY_MS2 / 5.0f) * (float)PWM_MAX_DUTY;

// PID Controllers
PIDController pidVerticalThrust;
PIDController pidPitchStabilizer;
PIDController pidRollStabilizer;

// ----------------------------------------------------------------------------
// BLE SERVER CALLBACKS
// ----------------------------------------------------------------------------
class ShayakServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) override {
        bleClientConnected = true;
        Serial.println("[BLE] Client connected.");
    }

    void onDisconnect(BLEServer* pServer) override {
        bleClientConnected = false;
        Serial.println("[BLE] Client disconnected. Restarting advertising...");
        pServer->getAdvertising()->start();
    }
};

// ----------------------------------------------------------------------------
// HARDWARE I2C & MPU REGISTERS
// ----------------------------------------------------------------------------
bool initMPU() {
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN, I2C_CLOCK_SPEED);

    // Check WHO_AM_I register (0x75)
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x75);
    if (Wire.endTransmission() != 0) {
        Serial.println("[ERROR] MPU not detected on I2C bus!");
        return false;
    }

    Wire.requestFrom(MPU_ADDR, 1);
    uint8_t chipId = Wire.read();
    Serial.printf("[MPU] Chip ID: 0x%02X\n", chipId);

    // Wake up MPU (clear SLEEP bit in PWR_MGMT_1, register 0x6B)
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x6B);
    Wire.write(0x00);
    Wire.endTransmission();
    delay(50);

    // Configure Gyro Full Scale (+/- 250 dps)
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x1B);
    Wire.write(0x00);
    Wire.endTransmission();

    // Configure Accel Full Scale (+/- 2g)
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x1C);
    Wire.write(0x00);
    Wire.endTransmission();

    // Configure DLPF (Digital Low Pass Filter) to 44 Hz bandwidth
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x1A);
    Wire.write(0x03);
    Wire.endTransmission();

    Serial.println("[MPU] Initialized successfully at 400 kHz I2C.");
    return true;
}

void readSensorRaw(float &ax, float &ay, float &az, float &gx, float &gy, float &gz) {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x3B); // ACCEL_XOUT_H register
    Wire.endTransmission(false);
    Wire.requestFrom(MPU_ADDR, 14, true);

    if (Wire.available() >= 14) {
        int16_t raw_ax = (Wire.read() << 8) | Wire.read();
        int16_t raw_ay = (Wire.read() << 8) | Wire.read();
        int16_t raw_az = (Wire.read() << 8) | Wire.read();
        int16_t raw_temp = (Wire.read() << 8) | Wire.read(); // Unused
        int16_t raw_gx = (Wire.read() << 8) | Wire.read();
        int16_t raw_gy = (Wire.read() << 8) | Wire.read();
        int16_t raw_gz = (Wire.read() << 8) | Wire.read();
        (void)raw_temp;

        // Convert to m/s^2 and deg/sec
        ax = ((float)raw_ax / ACCEL_SCALE_2G) * GRAVITY_MS2;
        ay = ((float)raw_ay / ACCEL_SCALE_2G) * GRAVITY_MS2;
        az = ((float)raw_az / ACCEL_SCALE_2G) * GRAVITY_MS2;

        gx = (float)raw_gx / GYRO_SCALE_250DPS;
        gy = (float)raw_gy / GYRO_SCALE_250DPS;
        gz = (float)raw_gz / GYRO_SCALE_250DPS;
    }
}

// ----------------------------------------------------------------------------
// 100 Hz HARD REAL-TIME KINEMATIC CONTROL TASK (CORE 0)
// ----------------------------------------------------------------------------
void kinematicControlTask(void *pvParameters) {
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xFrequency = pdMS_TO_TICKS(1000 / CONTROL_FREQ_HZ); // 10 ms = 100 Hz

    float ax, ay, az, gx, gy, gz;
    uint32_t loopCounter = 0;

    Serial.printf("[CORE 0] Kinematic Control Task running on Core %d\n", xPortGetCoreID());

    for (;;) {
        vTaskDelayUntil(&xLastWakeTime, xFrequency);

        readSensorRaw(ax, ay, az, gx, gy, gz);

        // 1. SENSOR FUSION (6-DOF Complementary Filter)
        // Convert accelerometer readings into Pitch and Roll estimates
        float pitch_acc = atan2f(-ax, sqrtf(ay * ay + az * az)) * (180.0f / M_PI);
        float roll_acc  = atan2f(ay, az) * (180.0f / M_PI);

        // Integrate gyroscope rates and fuse with accelerometer tilt
        pitch = FILTER_ALPHA * (pitch + gy * DT_SEC) + (1.0f - FILTER_ALPHA) * pitch_acc;
        roll  = FILTER_ALPHA * (roll  + gx * DT_SEC) + (1.0f - FILTER_ALPHA) * roll_acc;
        yaw   += gz * DT_SEC; // Open-loop gyro integration for yaw

        // Keep angles normalized
        if (yaw >= 360.0f) yaw -= 360.0f;
        else if (yaw < 0.0f) yaw += 360.0f;

        // 2. INERTIAL COORDINATE PROJECTION FOR ZERO-G BALANCE
        // Transform body-frame accelerations to earth vertical inertial axis:
        // a_z_inertial = -ax * sin(pitch) + ay * sin(roll)*cos(pitch) + az * cos(roll)*cos(pitch)
        float pitch_rad = pitch * (M_PI / 180.0f);
        float roll_rad  = roll  * (M_PI / 180.0f);

        float a_z_inertial = -ax * sinf(pitch_rad) 
                             + ay * sinf(roll_rad) * cosf(pitch_rad) 
                             + az * cosf(roll_rad) * cosf(pitch_rad);

        // Physics Goal: Net force along vertical axis satisfies F_net = 0
        // Net vertical acceleration error: e = a_z_inertial - g (Target: 0 m/s^2 deviation)
        float accel_error = a_z_inertial - GRAVITY_MS2;
        float f_net_error = PLATFORM_MASS_KG * accel_error; // In Newtons

        // 3. COUNTER-THRUST PID CONTROL COMPUTATION
        // Vertical thrust output negating gravitational drop
        float pid_thrust_correction = pidVerticalThrust.compute(0.0f, accel_error, DT_SEC);
        float total_thrust_pwm = BASE_GRAVITY_PWM + pid_thrust_correction;

        // Clamp to PWM boundaries
        if (total_thrust_pwm < 0.0f) total_thrust_pwm = 0.0f;
        if (total_thrust_pwm > (float)PWM_MAX_DUTY) total_thrust_pwm = (float)PWM_MAX_DUTY;

        uint16_t thrust_pwm_val = (uint16_t)total_thrust_pwm;
        ledcWrite(PWM_CHANNEL_Z, thrust_pwm_val);

        // Active Pitch & Roll counter-torque correction
        float pitch_pwm = pidPitchStabilizer.compute(0.0f, pitch, DT_SEC);
        float roll_pwm  = pidRollStabilizer.compute(0.0f, roll, DT_SEC);
        ledcWrite(PWM_CHANNEL_PITCH, (uint32_t)constrain((int)pitch_pwm + 512, 0, PWM_MAX_DUTY));
        ledcWrite(PWM_CHANNEL_ROLL,  (uint32_t)constrain((int)roll_pwm  + 512, 0, PWM_MAX_DUTY));

        // 4. TREMOR JITTER VARIANCE COMPUTATION (4-12 Hz Bio-marker Extraction)
        // High-pass filter dynamic jitter: a_dyn = a_z_inertial - GRAVITY_MS2
        tremorAccelBuffer[tremorBufferIndex] = accel_error;
        tremorBufferIndex = (tremorBufferIndex + 1) % TREMOR_WINDOW_SIZE;

        // Calculate variance across the sliding window
        float sum = 0.0f;
        for (int i = 0; i < TREMOR_WINDOW_SIZE; ++i) {
            sum += tremorAccelBuffer[i];
        }
        float mean = sum / (float)TREMOR_WINDOW_SIZE;
        float var_sum = 0.0f;
        for (int i = 0; i < TREMOR_WINDOW_SIZE; ++i) {
            float diff = tremorAccelBuffer[i] - mean;
            var_sum += diff * diff;
        }
        tremorFilteredVar = var_sum / (float)TREMOR_WINDOW_SIZE;

        // 5. QUEUE TELEMETRY PACKET (Downsample transmission to 25 Hz for BLE efficiency)
        if (++loopCounter % 4 == 0) {
            TelemetryPacket packet;
            packet.roll_deg = roll;
            packet.pitch_deg = pitch;
            packet.yaw_deg = yaw;
            packet.vertical_accel_ms2 = a_z_inertial;
            packet.net_force_error_n = f_net_error;
            packet.tremor_variance = tremorFilteredVar;
            packet.thrust_pwm_z = thrust_pwm_val;
            packet.timestamp_ms = millis();

            // Non-blocking queue send; overwrite if full
            xQueueOverwrite(telemetryQueue, &packet);
        }
    }
}

// ----------------------------------------------------------------------------
// BLE TELEMETRY STREAMING TASK (CORE 1)
// ----------------------------------------------------------------------------
void bleTelemetryTask(void *pvParameters) {
    Serial.printf("[CORE 1] BLE Telemetry Task running on Core %d\n", xPortGetCoreID());
    TelemetryPacket packet;

    for (;;) {
        // Wait for incoming packet from Core 0
        if (xQueueReceive(telemetryQueue, &packet, pdMS_TO_TICKS(50)) == pdTRUE) {
            if (bleClientConnected && pTelemetryChar != nullptr) {
                pTelemetryChar->setValue((uint8_t*)&packet, sizeof(TelemetryPacket));
                pTelemetryChar->notify();
            }
        }
    }
}

// ----------------------------------------------------------------------------
// ARDUINO SETUP & SYSTEM INITIALIZATION
// ----------------------------------------------------------------------------
void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.println("\n========================================================");
    Serial.println("  SHAYAK-AI: Active Kinematic Stabilization Starting   ");
    Serial.println("========================================================");

    // Initialize PWM channels
    ledcSetup(PWM_CHANNEL_Z, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);
    ledcSetup(PWM_CHANNEL_PITCH, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);
    ledcSetup(PWM_CHANNEL_ROLL, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);

    ledcAttachPin(THRUST_PWM_PIN_Z, PWM_CHANNEL_Z);
    ledcAttachPin(THRUST_PWM_PIN_PITCH, PWM_CHANNEL_PITCH);
    ledcAttachPin(THRUST_PWM_PIN_ROLL, PWM_CHANNEL_ROLL);

    // Set neutral PWM
    ledcWrite(PWM_CHANNEL_Z, 0);
    ledcWrite(PWM_CHANNEL_PITCH, 512);
    ledcWrite(PWM_CHANNEL_ROLL, 512);

    // Initialize PID Controllers
    // Kp = 45.0, Ki = 8.0, Kd = 4.5 for vertical thrust
    pidVerticalThrust.init(45.0f, 8.0f, 4.5f, 200.0f, -BASE_GRAVITY_PWM, PWM_MAX_DUTY - BASE_GRAVITY_PWM);
    // Angular balance PIDs
    pidPitchStabilizer.init(12.0f, 1.2f, 2.8f, 100.0f, -512.0f, 511.0f);
    pidRollStabilizer.init(12.0f, 1.2f, 2.8f, 100.0f, -512.0f, 511.0f);

    // Initialize MPU6050
    if (!initMPU()) {
        Serial.println("[CRITICAL] IMU failure. Halting.");
        while (1) { delay(1000); }
    }

    // Initialize FreeRTOS Inter-Core Queue (Length 1, overwrite mode)
    telemetryQueue = xQueueCreate(1, sizeof(TelemetryPacket));

    // Initialize BLE Server on Core 1
    BLEDevice::init("SHAYAK-STABILIZER-ESP32");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ShayakServerCallbacks());

    BLEService* pService = pServer->createService(SHAYAK_SERVICE_UUID);

    pTelemetryChar = pService->createCharacteristic(
        TELEMETRY_CHAR_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pTelemetryChar->addDescriptor(new BLE2902());

    pControlChar = pService->createCharacteristic(
        CONTROL_CHAR_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );

    pService->start();

    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SHAYAK_SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06); // functions that help with iPhone connections issue
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("[BLE] Advertising started as 'SHAYAK-STABILIZER-ESP32'");

    // Pin Kinematic Control Loop to Core 0 (High Priority 5)
    xTaskCreatePinnedToCore(
        kinematicControlTask,
        "KinematicCtrlTask",
        4096,
        NULL,
        5,
        NULL,
        0
    );

    // Pin BLE Telemetry Transmission to Core 1 (Priority 2)
    xTaskCreatePinnedToCore(
        bleTelemetryTask,
        "BLETelemetryTask",
        4096,
        NULL,
        2,
        NULL,
        1
    );

    Serial.println("[SYSTEM] Dual-core tasks pinned and running.");
}

void loop() {
    // Empty: Core 0 and Core 1 tasks execute asynchronously under FreeRTOS
    vTaskDelay(pdMS_TO_TICKS(1000));
}
