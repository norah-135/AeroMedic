# 4.4 Payload Box Subsystem Requirements

## 4.4.1 Overview
The Tethered Payload Box Subsystem serves as the immediate field edge-terminal for the AeroMedic platform. Engineered as a lightweight, high-efficiency smart edge device (500g), the payload box functions as a secure, ruggedized container designed to transport and deliver critical medical countermeasures (an automated EpiPen auto-injector and a chemical pulse oxygen generator).

The subsystem eliminates onboard battery overhead by drawing power directly from the VTOL drone's primary battery pack via a 7-meter Kevlar-reinforced hybrid umbilical cable, while executing command data links through a noise-immune industrial serial protocol (RS-485 / CAN-Bus). The box integrates an interactive physician-controlled Audio/Visual guidance system and an electromechanical locking mechanism governed by a robust Multi-Tier Fail-Safe Unlocking Architecture to guarantee zero-fail medical access under severe environmental and emergency conditions.

**Key Components:**
* **Microcontroller:** ESP32-S3-MINI (Compact MCU with built-in audio DSP for clear voice communications and multi-tier unlocking)
* **Power Management:** High-Voltage Step-Down Buck Converter (Umbilical Power Ingestion)
* **Umbilical Tether:** 7-Meter Kevlar-Reinforced Hybrid Umbilical Cable (Power Lines + RS-485 Data Bus)
* **Locking Mechanism:** Electric Solenoid Lock (App / Wristband / Doctor Override) + Manual Emergency Pull-Handle
* **Thermal Containment Zone:** Fiberglass Thermal Insulation Chamber (Chemical Oxygen Candle Isolation)
* **Human-Machine Interface (HMI):** 2.8" Sunlight-Readable IPS Display (SPI), 85dB Waterproof Speaker, Recessed MEMS Microphone with Gore-Tex Acoustic Vent.
* **Medical Payload:** Auto-Injectable EpiPen, Pulse Chemical Oxygen Generator (Electronic Ignition Module)

---

## 4.4.2 Functional Requirements (FR)

| ID | Requirement Description | Priority |
| :--- | :--- | :--- |
| **PB-FR-01** | The subsystem shall step down high-voltage power received from the drone's primary umbilical tether using an embedded Buck Converter to supply all internal electronics without requiring an internal primary battery. | Critical |
| **PB-FR-02** | The ESP32 microcontroller shall execute bidirectional serial data communications with the drone edge computer over an industrial RS-485 interface to resist electromagnetic interference across the 7-meter umbilical cable. | Critical |
| **PB-FR-03** | The subsystem shall scan and authenticate the patient's smart wristband hardware ID via the ESP-NOW protocol, automatically releasing the electromechanical lock when the wristband is within close proximity < 2m (based on RSSI thresholding). | Critical |
| **PB-FR-04** | The subsystem shall receive encrypted BLE commands from the AeroMedic application to release the lock immediately upon user request | High |
| **PB-FR-05** | The subsystem shall release the electromechanical lock immediately when receiving encrypted remote command send by the attending emergency physician via the drone's primary cellular (5G/LoRa) link relayed through the umbilical bus. | Critical |
| **PB-FR-06** | The subsystem shall incorporate an unpowered, purely mechanical shear-latch override mechanism equipped with an external pull-handle protected by a breakable, tamper-evident seal to allow manual forced entry during total electronic power or system failure. | Critical |
| **PB-FR-07** | The subsystem shall stream live bidirectional audio between the emergency physician and the scene, utilizing an embedded recessed microphone and high-output speaker powered via the umbilical data bridge. | High |
| **PB-FR-08** | The OLED display shall display step-by-step guidance icons and countdown timers send by physicians to help the patient use the EpiPen correctly. | High |
| **PB-FR-09** | The subsystem shall activate the chemical oxygen generator mechanically when the user pulls the oxygen mask | Critical |
| **PB-FR-10** | The box subsystem shall remain in a low-power sleep state during flight and wake up upon receiving a signal from the drone or via mechanical manual override | High |

---

## 4.4.3 Payload Box Non-Functional Requirements (NFR)

### Specification Standards Alignment:
The Smart Payload Box Subsystem operates as a critical Cyber-Physical Medical Device. Therefore, its requirements are specified in accordance with ISO/IEC/IEEE 15288 for systems engineering lifecycle integration, and ISO/IEC 25010 for system quality and environmental attributes. Furthermore, hardware thermal isolation and emergency access safety mechanisms comply with international medical device safety framework principles (ISO 14971 and IEC 60601-1), ensuring strict reliability, thermal containment, and fault-tolerant operation during critical field deployments.

| ID | Requirement Description | Standard Alignment | Operational Context & Calculation Basis | Priority |
| :--- | :--- | :--- | :--- | :--- |
| **PB-NFR-01** | The total mass of the payload box (housing internal electronics, EpiPen auto-injector, and oxygen candle) shall not exceed 800 g. | ISO/IEC/IEEE 15288: System Architecture & Resource Constraints | Prevents overloading drone propulsion systems and maintains stable VTOL equilibrium during flight. | Critical |
| **PB-NFR-02** | The outer casing shall be rated IP65 against heavy dust and rain exposure. | ISO 25010: Reliability (Environmental Robustness) | Protects against sudden atmospheric changes during mountain missions. | High |
| **PB-NFR-03** | The payload enclosure shall withstand low velocity drop impacts from up to 60 cm | ISO 25010: Structural Robustness (ISO 2248 Drop Test Standard) | Protects internal components from impact shock when released from the tether near the landing site. | Critical |
| **PB-NFR-04** | The subsystem shall process and execute lock release with zero noticeable latency during medical emergencies. | ISO 25010: Performance Efficiency (Time Behavior) | Guarantees instant medical payload accessibility for the patient or bystander during life-threatening events. | Critical |
| **PB-NFR-05** | The fiberglass thermal chamber shall maintain surface temperature below 45°C during oxygen generation. | IEC 60601-1 / ISO 14971: Medical Thermal Safety (ISO 13732-1) | Safely contains chemical heat (up to 200°C) inside the chamber, preventing skin burns. | Critical |
| **PB-NFR-06** | The link shall enforce CRC error-checking to detect and reject corrupted packets during communication. | ISO/IEC/IEEE 15288: Electromagnetic Compatibility (ISO 11452) | Prevents execution of corrupted commands or faulty lock triggers caused by electrical noise. | High |
