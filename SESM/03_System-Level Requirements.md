##  3. System-Level Requirements

### 3.1 Functional Requirements (FR)

| ID | Requirement Description | Priority |
| :--- | :--- | :--- |
| **FR-01** | The smart wristband shall detect sudden fall events utilizing an on-board Inertial Measurement Unit (IMU) and generate an immediate emergency alert signal. | Critical |
| **FR-02** | The system shall support four redundant communication channels for alert reporting. | Critical |
| **FR-03** | The cloud platform shall automatically verify the patient's Electronic Health Record (EHR) to confirm payload suitability before approving the drone deployment. | High |
| **FR-04** | The drone navigation system shall receive target coordinates, initiate autonomous takeoff, and navigate to the incident location without human intervention. | Critical |
| **FR-05** | The smart payload box shall trigger an electronic locking mechanism to unlock automatically upon arrival confirmation via (ESP-NOW, cloud command, or fallback timer). | Critical |
| **FR-06** | The system shall start and manage an audio/video streaming session using WebRTC between the on-duty physician and the first responder. | High |
| **FR-07** | The smart wristband shall transmit periodic heartbeat signals to the cloud platform to monitor battery health and network connection status. | Medium |
| **FR-08** | The system shall detect and bind the wristband to the proximity patient using BLE Beacon broadcasting without requiring a manual pairing process. | High |

###  3.2 Non-Functional Requirements (NFR)

| ID | Quality Attribute | Strict Metric / Measurement Criteria |
| :--- | :--- | :--- |
| **NFR-01** | Alert Processing Latency | The duration from fall detection to alert transmission to the cloud shall be < 3 seconds. |
| **NFR-02** | Dispatch Response Time | The time from receiving medical cloud clearance to actual drone takeoff shall be < 30 seconds. |
| **NFR-03** | Mission Flight Time | The maximum duration for the VTOL drone to reach the furthest point within the operational boundary shall be < 5 minutes. |
| **NFR-04** | Payload Weight Limitation | The total weight of the smart payload box (loaded with the EpiPen) shall be ≤ 500 grams. |
| **NFR-05** | Wind Resistance | The VTOL drone aerodynamic structure shall withstand crosswinds and gusts up to 40 km/h. |
| **NFR-06** | Network Availability | High-availability fallback routing between 5G and LoRa networks shall guarantee a connection uptime of ≥ 99.9%. |
| **NFR-07** | Wristband Battery Life | The smart wristband power management system shall sustain continuous operational broadcasting for ≥ 12 hours per charge. |
| **NFR-08** | Geospatial Accuracy | The GPS/GNSS positioning subsystem for both the drone and the wristband shall maintain an accuracy radius within < 2.5 meters. |
| **NFR-09** | Data Security & Privacy | All telemetry and patient data transmitted between edge nodes and the cloud shall be encrypted using TLS 1.3 and AES-256. |
| **NFR-10** | Thermal Protection | The payload enclosure insulation shall maintain an internal temperature between 15°C and 30°C during flight to preserve medication viability. |