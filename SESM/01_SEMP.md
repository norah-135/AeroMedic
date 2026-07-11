##  1. Systems Engineering Management Plan (SEMP)
This plan serves as the governing constitution for the AeroMedic project. It establishes the technical strategy to manage the multi-disciplinary integration of hardware, embedded firmware, and cloud platforms as a sole engineer, ensuring system reliability and safety-critical execution.
 
### 1.1 Technical Project Control & Tools

* **Configuration Management:** 
  The GitHub repository serves as the Single Source of Truth (SSOT). To maintain strict self-discipline during independent development, interface data structures (JSON Payloads) and communication protocols are frozen as a personal baseline. This serves as a vital self-reminder: network ports (e.g., WebSocket port 8000 for Flutter Web, TCP port 1883 for the Python backend core) should only be modified after updating this blueprint first to ensure systematic cross-system consistency.

* **Technical Performance Measures (TPMs):**
  * **Critical Payload Weight:** The total weight of the smart payload box must not exceed 500 grams (housing the automatic EpiPen and the chemical oxygen candle).
  * **Standard Response Time:** Autonomous takeoff and aerial arrival at the incident coordinates must take less than 5 minutes.
  * **Environmental Resilience:** The VTOL drone architecture must maintain stable navigation under mountain wind speeds of up to 40 km/h.

### 1.2 Engineering Domain Integration & WBS (Work Breakdown Structure)
To manage system complexity independently, I have broken down the development lifecycle into three distinct technical domains that interface seamlessly through a predefined Interface Control Document (ICD):

1. **Cloud & Application Communication Domain:** Focuses on architecting the real-time data link between the application interface and the emergency cloud infrastructure. The ICD strictly defines this interface by mapping how the application publishes emergency alerts and subscribes to live telemetry through the cloud MQTT broker, freezing the exact JSON payload structures, topics, and network ports to ensure seamless, low-latency communication.
2. **Hardware & Firmware Domain:** Focuses on programming the ESP32 microcontroller in C++ to process real-time IMU sensor streams for automated fall-detection logic. It implements a non-connecting BLE Advertising protocol (Beacon Mode) to continuously broadcast vital telemetry directly inside the advertisement packets, successfully eliminating any user pairing requirements and bypassing standard control-center Bluetooth toggle restrictions, while utilizing peer-to-peer ESP-NOW protocols for zero-config proximity payload authentication.
3. **Autopilot & Edge AI Domain:** Focuses on configuring the PX4 Software In The Loop (SITL) autonomous flight environment, developing the Python coordinate injection pipeline, and deploying the YOLOv8-Thermal computer vision model on the Raspberry Pi 5 edge computer.
 
### 1.3 Technical Risk & Mitigation Matrix
To ensure absolute system availability during critical emergencies, I have designed a fail-safe hierarchy that eliminates any single point of failure (SPOF):

| Risk ID | Technical Risk | Impact | Preventative Engineering Strategy & Backup |
| :--- | :--- | :--- | :--- |
| **RSK-01** | Drop in 5G/4G network in mountain. | Critical | Switch to LoRa backup to broadcast coordinate. |
| **RSK-02** | Autonomous flight mission rejection by the PX4 Autopilot system during coordinate injection. | High | Programmatically enforcing strict landing waypoint parameters within the Python coordinate injection script to guarantee immediate mission validation and execution. |
| **RSK-03** | Bystander or patient ignorance regarding the proper deployment and utilization of the delivered medical payload (EpiPen/Oxygen). | High | Integration of a rugged, embedded display on the smart payload box coupled with a live, bidirectional WebRTC audio/video broadcast connecting the emergency physician directly to the scene to visually guide the user. |
| **RSK-04** | Delivery or unlocking of an incompatible or hazardous medical payload due to lack of patient clinical history verification. | Critical | Architecture of a cloud-native Medical Record Verification System that automatically cross-references the patient's authenticated electronic health records (EHR) before authorizing the drone dispatch and payload lock release. |