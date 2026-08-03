# 4.5 Drone Subsystem Requirements

## 4.5.1 Overview & System Description
The Drone Subsystem serves as the primary autonomous aerial transport node within the AeroMedic ecosystem. Engineered as a High-Altitude / Mountain-Resilient VTOL platform, it combines the vertical landing flexibility of a multirotor with the long-range cruise efficiency of a fixed-wing aircraft. 
The drone operates semi-autonomously under the PX4 Autopilot stack, executing target coordinate injection, real-time computer vision landing-zone identification, and tethered payload delivery.

**Key Structural & Hardware Components:**
* **Autopilot Flight Controller:** Pixhawk / PX4 Autopilot system executing SITL and real-time autonomous navigation flight modes.
* **Edge Computing Computer:** Raspberry Pi 5 running a YOLOv8-Thermal computer vision pipeline to detect human targets and clear landing zones in rugged terrains.
* **Long-Range Data Link Modules:** Primary Cellular (5G/4G) telemetry transceiver with LoRa backhaul fallback for remote mountain operations.
* **Tether Management Mechanism:** Electromechanical winch and cable control system hosting the 7-meter Kevlar-reinforced hybrid umbilical tether.
* **Power Distribution System:** High-capacity Li-Ion 6S Pack (High-C Rating battery pack supplying propulsion motors and stepping down high-voltage power over the umbilical cable to power the payload box.

---

## 4.5.2 Functional Requirements (FR)

| ID | Requirement Description | Priority |
| :--- | :--- | :--- |
| **D-FR-01** | The drone navigation system shall ingest target emergency coordinates from the cloud core, validate mission parameters, and execute autonomous takeoff without human intervention. | Critical |
| **D-FR-02** | The onboard edge computer (Raspberry Pi 5) shall process thermal video streams using a YOLOv8 model to identify safe, obstacle-free landing and deployment zones. | High |
| **D-FR-03** | The drone shall execute a low-altitude descent (30cm( above ground), release the payload box, and issue a PAYLOAD_DROPPED serial signal over the RS-485 umbilical bus. | Critical |
| **D-FR-04** | The drone shall perform an adjacent landing near the dropped payload box, shut down its motors upon physical ground contact, and transmit a DRONE_LANDED confirmation signal to trigger the box arming state. | Critical |
| **D-FR-05** | The drone shall maintain continuous real-time telemetry streaming (GPS coordinates, speed, battery level, and flight ETA) to the cloud broker via 5G, automatically switching to LoRa when cellular coverage is lost. | Critical |
| **D-FR-06** | The drone subsystem shall supply high-voltage operational power continuously down the 7-meter hybrid umbilical tether to energize all payload box electronics during deployment. | Critical |

---

## 4.5.3 Drone Non-Functional Requirements Standards

### Specification Standards Alignment:
The Drone Subsystem requirements are defined in compliance with ISO/IEC/IEEE 15288 for systems engineering integration and ISO/IEC 25010 for system quality and operational performance. Additionally, navigation resilience, landing precision, and flight safety constraints adhere to international unmanned aviation system (UAS) reliability standards (ASTM F3269), ensuring safe autonomous operation under severe environmental conditions and complex mountain topographies.

| ID | Requirement Description | Standard Alignment | Operational Context & Calculation Basis | Priority |
| :--- | :--- | :--- | :--- | :--- |
| **D-NFR-01** | The VTOL drone shall reach the farthest incident boundary> 15 km within < 4 min under wind speeds up to 40. | ISO 25010: Performance Efficiency (Time Behavior) | Guarantees rapid emergency arrival during life threatening anaphylactic or hypoxemic events. | Critical |
| **D-NFR-02** | The drone propulsion system shall sustain stable flight dynamics with a net payload mass of up to 800g | ISO/IEC/IEEE 15288: System Architecture & Mass Limits | Accommodates the smart payload box, internal electronics, auto-injectors, and oxygen candles without compromising flight equilibrium. | Critical |
| **D-NFR-03** | Autonomous GPS and YOLOv8 landing site selection shall achieve a positioning precision within 2.5m. | ISO 25010: Operational Precision & Reliability | Ensures safe adjacent landing near the patient while avoiding obstacles, trees, or rugged terrain. | Critical |
| **D-NFR-04** | The aerodynamic structure shall withstand crosswinds and turbulent gusts up to 40 km/h during flight and landing. | ISO 25010: Environmental Robustness | Maintains flight stability in high-altitude mountain environments under sudden weather shifts. | High |
| **D-NFR-05** | Switching telemetry routes between primary 5G/4G cellular links and secondary LoRa backhauls shall execute in < 1s upon signal loss. | ISO 25010: Fault Tolerance & Availability | Guarantees uninterrupted flight command ingestion when traversing cellular dead zones in valleys or mountains. | Critical |
| **D-NFR-06** | All control commands, target coordinates, and live telemetry streams shall be encrypted in transit using TLS 1.3 and AES-256. | ISO 25010: Security & Confidentiality | Prevents unauthorized spoofing, signal hijacking, or coordinate tampering during autonomous flight. | High |
