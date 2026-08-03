# 4.2 Mobile Application Subsystem Requirements

## 4.2.1 Overview
The Mobile Application Subsystem acts as a critical communication bridge within the AeroMedic ecosystem. Developed using Flutter and Dart, this cross-platform application links the patient's bio-wearable device (via BLE) to the cloud backend (via MQTTS) and tracks the autonomous medical drone dispatch. The application is designed to prioritize ultra-low latency, strict data privacy, high visual contrast under stress, and robust operating system persistence.

**Key Architectural Components:**
* **Framework & Language:** Flutter & Dart (Clean Architecture with BLoC/Provider state management).
* **Local Communication Interface:** flutter_blue_plus for BLE data ingestion.
* **Cloud Telemetry Client:** MQTTS Client with mutual TLS (mTLS) authentication.

---

## 4.2.2 Functional Requirements (FR)

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| **APP-FR-01** | The application shall allow users to create and securely store a local medical profile including critical allergies, blood type, and respiratory history. | High |
| **APP-FR-02** | The application shall continuously scan for and identify the unique hardware identifier of the AeroMedic Wearable Subsystem via BLE advertisement packets (Beacon Mode). | Critical |
| **APP-FR-03** | The application shall intercept  and process the live stream of SpO2 and heart rate telemetry embedded directly within the wearable's broadcasted BLE beacon payloads. | Critical |
| **APP-FR-04** | The application shall execute a 20-second visual and auditory pre-alert countdown upon receiving an emergency trigger (SpO2<85% accompanied by positive IMU fall detection data). | Critical |
| **APP-FR-05** | The application shall present a prominent, high-visibility "Cancel Alert" button alongside a secondary "Force Send Now" bypass button during the 20-second countdown. | Critical |
| **APP-FR-06** | The application shall automatically compile, encrypt, and publish an emergency payload (including GPS coordinates, timestamp, and medical profile) to the cloud via MQTT if the 20-second countdown expires or when "Force Send" Butten pressed. | Critical |
| **APP-FR-07** | The application shall display early warning push notifications and haptic vibrations when a gradual decline in oxygen saturation (SpO2<90%) is registered. | Medium |
| **APP-FR-08** | The application shall provide a manual Trigger on the primary dashboard for immediate drone requests. | High |
| **APP-FR-09** | The application shall render a map showing the drone's live route, current coordinates, and Estimated Time of Arrival (ETA). | High |
| **APP-FR-10** | The application shall compute the distance to the landed drone via BLE RSSI/UWB, and automatically transmit a secure proximity token to release the payload box's lock when the user is within < 2 meters. | Critical |
| **APP-FR-11** | The application shall utilize native Android (SYSTEM_ALERT_WINDOW) and iOS (Critical Alerts) APIs to bypass system locks, mute switches, or "Do Not Disturb" modes during an emergency countdown. | Critical |
| **APP-FR-12** | The application shall programmatically initiate a direct cellular voice call to the Saudi Red Cross (997) in parallel with the MQTT cloud alert transmission upon countdown expiration. | Critical |
| **APP-FR-12.2** | The application shall monitor the smartphone's native battery level (%) and low-power mode status via system APIs in real-time. | High |
| **APP-FR-12.8** | In Eco-Emergency Mode, the application shall suspend non-critical background services (including map tile downloads, UI animations, and log uploads), retaining only BLE ingestion, GPS acquisition, and MQTT publishing. | Critical |

---

## 4.2.3 Non-Functional Requirements (NFR)

### Performance & Response Time Requirements

| ID | Requirement | Target |
| :--- | :--- | :--- |
| **APP-NFR-01** | Processing and transmission latency of the emergency payload to the MQTT broker upon countdown expiration | < 1.5 seconds |
| **APP-NFR-02** | BLE data packet ingestion and UI state refresh rate | ≤ 500 ms |
| **APP-NFR-03** | Google Maps asset position rendering refresh interval | ≤ 1 second |

### Security, Safety & Privacy Requirements

| ID | Requirement |
| :--- | :--- |
| **APP-NFR-04** | All outgoing telemetry, vital signs, and patient health profiles must be encrypted in transit using MQTTS (MQTT over TLS 1.3) with mutual authentication (mTLS). |
| **APP-NFR-05** | Local caching of sensitive medical profiles and authentication tokens must be encrypted using AES-256 inside secure OS sandboxes (Keychain/Keystore). |
| **APP-NFR-06** | The application must enforce strict data minimization, ensuring personal identifiers are masked or tokenized before cloud ingestion, adhering to local healthcare privacy frameworks. |

### Reliability, Architecture & Maintainability Requirements

| ID | Requirement |
| :--- | :--- |
| **APP-NFR-07** | The codebase must strictly adhere to Clean Architecture principles, ensuring that data layers, domain entities, and presentation presentation logic are decoupled to support future sensor additions. |
| **APP-NFR-08** | The application must achieve a crash-free session rate of ≥ 99.9% across both supported platforms (iOS and Android). |

### Usability Under Stress Requirements

| ID | Requirement |
| :--- | :--- |
| **APP-NFR-09** | The UI must support a high-contrast theme with large, touch-target buttons (minimum 64x64 density pixels) usable under direct sunlight and high-stress scenarios. |
| **APP-NFR-10** | The layout must prevent any screen dimming or automatic sleep timeouts while an active emergency event or countdown is underway. |

### OS Permissions & Background Management Requirements

| ID | Requirement |
| :--- | :--- |
| **APP-NFR-11** | The BLE background service must run as an OS-level Foreground Service (with persistent notification) to prevent the operating system from terminating the process to save memory. |
| **APP-NFR-12** | The application must gracefully re-acquire or prompt for critical permissions (Location, Bluetooth, Background Fetch, Overlay) upon startup if revoked by the user. |

### Network Resilience & Interoperability Requirements

| ID | Requirement |
| :--- | :--- |
| **APP-NFR-13** | In the event of 4G/5G connection loss during an emergency trigger, the app must queue the data packet locally and re-attempt transmission at 1-second intervals until a handshake is confirmed. |
| **APP-NFR-14** | The application shall implement an automatic data-saving mode under highly degraded networks (Edge/3G), suspending non-essential map tile downloads and prioritizing the ingestion of raw, low-bandwidth coordinate strings (lat/long) to sustain live drone tracking. |

### State Management & Concurrency Requirements

| ID | Requirement |
| :--- | :--- |
| **APP-NFR-15** | The application must run asynchronous background isolates for BLE incoming streams to prevent high-frequency sensor data from locking or lagging the UI thread. |
| **APP-NFR-16** | The state management layer (BLoC/Provider) must guarantee that the "Cancel Alert" button interaction takes absolute event-loop priority over telemetry updates. |
