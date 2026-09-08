# SHAYAK-AI: Embedded Active Kinematic Stabilization Module

## Overview
This module runs on an **ESP32 dual-core Xtensa LX6** microcontroller paired via Fast I2C (400 kHz) with an **MPU6050 / MPU9250 6-DOF IMU**. It executes active real-time counter-thrust and stabilization to negate gravitational acceleration along the vertical axis ($g = 9.80665\text{ m/s}^2$) so that the net force satisfies:
$$F_{\text{net}} = m \cdot (a_z^{\text{inertial}} - g) = 0$$

## Pinout & Wiring
| MPU6050 Pin | ESP32 Pin | Function |
|-------------|-----------|----------|
| VCC         | 3V3       | Power Supply (3.3V) |
| GND         | GND       | Ground |
| SDA         | GPIO 21   | I2C Data (400 kHz) |
| SCL         | GPIO 22   | I2C Clock (400 kHz) |
| INT         | GPIO 4    | IMU Data Ready (Optional hardware interrupt) |

### Actuator / Thrust Vector PWM Outputs
| Output Channel | ESP32 Pin | Frequency | Function |
|----------------|-----------|-----------|----------|
| Channel 0      | GPIO 18   | 20 kHz    | Vertical Z counter-thrust PWM (Negates $g$) |
| Channel 1      | GPIO 19   | 20 kHz    | Pitch anti-tilt torque PWM |
| Channel 2      | GPIO 23   | 20 kHz    | Roll anti-tilt torque PWM |

## Dual-Core Architecture
- **Core 0 (`kinematicControlTask`)**:
  - Hard real-time 100 Hz (`10ms` cycle via `vTaskDelayUntil`).
  - 6-DOF complementary filter fusing gyroscope angular rates and accelerometer tilt vectors.
  - Coordinate rotation from body coordinate frame to inertial earth-frame vertical acceleration.
  - High-precision PID calculation with anti-windup clamping to drive counter-thrust actuators.
  - 4–12 Hz tremor jitter variance extraction over a 500 ms sliding window.
  - Non-blocking push to FreeRTOS overwrite queue.
- **Core 1 (`bleTelemetryTask`)**:
  - BLE GATT Server with UUID `4fafc201-1fb5-459e-8fcc-c5c9c331914b`.
  - Non-blocking consumption of telemetry packets from the queue.
  - Downsampled notifications at 25 Hz to conserve BLE bandwidth and prevent radio latency from jittering the control loop on Core 0.

## BLE Telemetry Packet Structure (30 Bytes Packed)
```c
struct TelemetryPacket {
    float roll_deg;             // Orientation Roll (-180 to +180 deg)
    float pitch_deg;            // Orientation Pitch (-90 to +90 deg)
    float yaw_deg;              // Orientation Yaw (0 to 360 deg)
    float vertical_accel_ms2;   // Inertial vertical acceleration (m/s^2)
    float net_force_error_n;    // Net force error F_net along vertical axis (N)
    float tremor_variance;      // Micro-jitter variance (4-12 Hz biomarker)
    uint16_t thrust_pwm_z;      // Current counter-thrust PWM duty (0 - 1023)
    uint32_t timestamp_ms;      // Hardware monotonic timestamp (ms)
};
```
