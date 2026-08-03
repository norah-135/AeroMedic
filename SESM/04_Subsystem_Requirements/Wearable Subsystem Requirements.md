# 4. Subsystem Requirements Specification

This section defines the detailed technical requirements for each subsystem within the AeroMedic system. The requirements are structured following established systems engineering practices, with software-related requirements aligned to the IEEE 830-1998 standard and the ISO/IEC 25010 quality model where applicable.

## 4.1 Wearable Subsystem Requirements

### 4.1.1 Overview

The Wearable Subsystem is the primary patient-side component of the AeroMedic system. It is responsible for continuous monitoring of vital signs (SpO₂ and heart rate), fall detection, and emergency alert initiation. The device operates as a low-power, always-on health monitor that communicates with both the mobile application (via BLE) and the Drone Station (via LoRa as a fail-safe), and the Cloud using Wi-Fi.

**Key Components:**
* **Microcontroller:** ESP32-C3 (with Integrated Wi-Fi & BLE 5.0)
* **MAX30102:** Pulse Oximeter & Heart Rate Sensor
* **ICM-42688-P:** 6 axis IMU Motion 
* **LoRa Transceiver:** Semtech SX1262
* **Power Source:** Rechargeable Li-Po Battery

---

### 4.1.2 Functional Requirements (FR)

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| **W-FR-01** | The wearable device shall continuously monitor the patient's SpO₂ (blood oxygen saturation) and heart rate at intervals ≤ 30 seconds. | Critical |
| **W-FR-02** | The wearable device shall detect fall events using IMU data analysis within < 3 seconds of the event occurrence. | Critical |
| **W-FR-03** | The wearable device shall transmit emergency alerts to the mobile application via BLE within < 1 second of detecting a critical event. | Critical |
| **W-FR-04** | The wearable device shall broadcast its unique hardware identifier via BLE advertisement packets (Beacon Mode) for proximity-based patient binding, eliminating the need for manual pairing. | High |
| **W-FR-05** | The wearable device shall utilize BLE as the primary communication channel, activating Wi-Fi as a secondary fail-safe only when BLE connectivity to the application is lost for > 10 s, and LoRa for emergency's. | Critical |
| **W-FR-06** | The wearable device shall transmit periodic health status packets to the cloud backend every 12 hours for predictive maintenance and battery monitoring. | Medium |
| **W-FR-07** | The wearable device shall store emergency alert data locally (in flash memory) for up to 24 hours if no network connectivity is available, and retransmit when connectivity is restored. | High |
| **W-FR-08** | The wearable device shall provide visual (LED) and haptic (vibration) feedback to the patient upon successful alert transmission or when anomaly happened and when the system acknowledges receipt. | Medium |
| **W-FR-09** | The wearable device shall keep the Wi-Fi module in an ultra-low-power Deep Sleep state by default, power it on only during BLE failures to transmit messages and shut it down immediately after transmission acknowledgment. | High |
| **W-FR-9.5** | The wearable device shall compile a daily health summary packet (including average/peak heart rate, SpO₂ trends, and sleep/activity duration) and transmit it to the cloud via Wi-Fi or BLE once every 24 hours to assist in long-term medical diagnosis. | High |

---

### 4.1.3 Non-Functional Requirements (NFR)

#### Performance Requirements

| ID | Requirement | Target |
| :--- | :--- | :--- |
| **W-NFR-01** | Fall detection latency from event occurrence to alert generation | < 3 seconds |
| **W-NFR-02** | BLE alert transmission latency from detection to mobile app receipt | < 1 second |
| **W-NFR-03** | Device boot-up time from power-on to full operation | < 5 seconds |
| **W-NFR-04** | Sensor data acquisition and processing cycle time | ≤ 5 seconds |

#### Power & Battery Requirements

| ID | Requirement | Target |
| :--- | :--- | :--- |
| **W-NFR-05** | Continuous battery life under normal monitoring conditions | ≥ 12 hours |
| **W-NFR-06** | Battery charging time (0% to 80%) via USB-C | ≤ 2 hours |

#### Environmental Requirements

| ID | Requirement |
| :--- | :--- |
| **W-NFR-07** | The wearable device shall be waterproof with an IP67 rating (dust-tight and protected against immersion up to 1 meter). |
| **W-NFR-8** | The wearable device shall operate within temperature range: 0°C to 80°C. |
| **W-NFR-9** | The wearable device shall withstand minor impacts and drops (up to 1.5 meters). |
| **W-NFR-10** | The device shall be lightweight, with total weight ≤ 100 grams. |

#### Communication & Interface Requirements

| ID | Requirement | Interface |
| :--- | :--- | :--- |
| **W-NFR-11** | The wearable device shall continuously stream vital signs and alerts via BLE to the mobile application under normal operating conditions. | BLE |
| **W-NFR-12** | The wearable device shall utilize 2.4 GHz Wi-Fi to establish a direct-to-cloud connection only when the mobile application is unresponsive and a pre-configured Wi-Fi network is available. | Wi-Fi |
| **W-NFR-13** | The wearable device shall communicate with the Drone station via LoRa (SX1276) at with a range ≥ 15 km in open terrain, as a fail-safe when cellular networks are unavailable. | LoRa |
| **W-NFR-14** | All data transmitted over BLE shall be encrypted using AES-128 encryption. | BLE |
| **W-NFR-15** | All data transmitted over LoRa shall be encrypted using AES-128 encryption. | LoRa |
| **W-NFR-16** | All data transmitted over Wi-Fi shall be secured using TLS 1.2 (HTTPS/MQTT over TLS) to ensure secure end-to-end cloud ingestion. | Wi-Fi |
| **W-NFR-16.5** | The wearable device shall authenticate with the cloud backend using device-specific X.509 certificates. | Wi-Fi |

#### Security, Safety & Privacy Requirements

| ID | Requirement |
| :--- | :--- |
| **W-NFR-17** | The wearable device shall store patient health data locally in encrypted format using AES-128. |
| **W-NFR-18** | The device shall implement a factory reset mechanism that permanently erases all stored patient data. |
| **W-NFR-19** | The device shall include tamper detection mechanisms that lock the device and erase data upon unauthorized physical access attempts. |
| **W-NFR-20** | The device shall only transmit anonymized patient identifiers (not full personal information) over wireless networks. |

#### Reliability & Maintainability Requirements

| ID | Requirement |
| :--- | :--- |
| **W-NFR-21** | The wearable device shall have a Mean Time Between Failures (MTBF) of ≥ 10,000 hours. |
| **W-NFR-22** | The device shall support firmware updates over-the-air (OTA) via BLE or LoRa (upon physical proximity). |
| **W-NFR-23** | The device shall record diagnostic logs for the last 30 days of operation, including battery health, sensor errors, and communication attempts. |

#### Usability Requirements

| ID | Requirement |
| :--- | :--- |
| **W-NFR-24** | The wearable device shall be designed for single-handed operation and comfortable continuous wear. |
| **W-NFR-25** | The device shall include a physical panic button for manual emergency activation that is easily accessible to the patient. 
