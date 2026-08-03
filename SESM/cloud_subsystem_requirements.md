# 4.3 Cloud Subsystem Requirements

## 4.3.1 Overview
The Cloud Subsystem serves as the central orchestration engine and intelligence core of the AeroMedic ecosystem. Developed using high-performance micro-services, it ingests real-time biomedical telemetry from edge devices (via MQTTS), evaluates emergency triggers, cross-references clinical records (EHR), and issues autonomous takeoff commands to the Drone Station. The cloud platform is architected to guarantee zero-packet-loss emergency routing, robust device authentication, and secure, high-concurrency stream management under critical failure conditions.

**Key Architectural Components:**
* **Core Runtime & Framework:** Node.js / Python FastAPIs (Containerized Microservices Architecture).
* **Telemetry Broker:** EMQX / Eclipse Mosquitto MQTTS Broker (with TLS 1.3 and Mutual Device Authentication).
* **Database Infrastructure:** PostgreSQL (Encrypted EHR & Device Registry) + Redis (In-Memory Ultra-Low-Latency Caching).
* **Real-time Signalling Client:** WebRTC Signalling Server for live video/audio streaming between first-responders and emergency physicians.

---

## 4.3.2 Functional Requirements (FR)

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| **C-FR-01** | The cloud platform shall maintain an MQTTS Broker to ingest alerts from the App (via 4G/5G bridging BLE), directly from the Wearable via Wi-Fi, or via Ground Gateways bridging LoRa over cellular. | Critical |
| **C-FR-02** | The cloud backend shall automatically validate the identity of incoming edge connections via device-specific X.509 digital certificates before granting broker access. | Critical |
| **C-FR-03** | Upon receiving an emergency trigger, the cloud platform shall query the patient's authenticated Electronic Health Record (EHR) database to verify payload suitability (e.g., EpiPen dosage/allergies) prior to dispatch clearance. | Critical |
| **C-FR-04** | The cloud core shall automatically evaluate GPS positioning data, allocate the nearest operational Drone Station, and compile a structured API Takeoff Order. | Critical |
| **C-FR-05** | The cloud platform shall establish and relay WebRTC signalling channels to connect the emergency physician's dashboard to the smart payload box's video/audio stream. | High |
| **C-FR-06** | The cloud system shall process and store periodic 12-hour wearable health status packets (battery health, log diagnostics) for predictive maintenance tracking. | Medium |
| **C-FR-07** | The cloud platform shall expose secure RESTful APIs to ingest fallback emergency parameters submitted manually by Red Cross dispatchers via Voice Call pathways. | High |
| **C-FR-08** | In the event of primary database latency, the cloud platform shall buffer all incoming emergency alerts in an in-memory Redis cache to prevent any packet dropping. | Critical |
| **C-FR-09** | The cloud backend shall broadcast real-time flight telemetry (drone coordinates, speed, and ETA) to both the mobile application and the physician dashboard simultaneously. | High |

---

## 4.3.3 Non-Functional Requirements (NFR)

### Performance & Response Time Requirements

| ID | Requirement | Target |
| :--- | :--- | :--- |
| **C-NFR-01** | Emergency payload processing, EHR validation, and drone dispatch command generation latency | < 200ms |
| **C-NFR-02** | Telemetry ingestion and WebSocket UI state refresh rate for active drone tracking | < 500 ms |
| **C-NFR-03** | Concurrent active telemetry stream handling without CPU utilization exceeding 70% | > 1,000 streams |

### Security, Safety & Privacy Requirements

| ID | Requirement |
| :--- | :--- |
| **C-NFR-04** | All cloud endpoints, APIs, and MQTT brokers must enforce TLS 1.3 encryption with Mutual Authentication (mTLS) for in-transit data protection. |
| **C-NFR-05** | All patient health profiles and EHR databases at rest must be encrypted using AES-256 with hardware-security module (HSM) key management. |
| **C-NFR-06** | The cloud platform must implement strict Role-Based Access Control (RBAC) and immutable audit logging for all medical record queries and drone dispatch triggers. |

### Reliability, Availability & Maintainability Requirements

| ID | Requirement |
| :--- | :--- |
| **C-NFR-07** | The cloud infrastructure shall guarantee high-availability deployment across redundant server nodes to maintain an uptime rate of 99.99%. |
| **C-NFR-08** | The cloud backend codebase shall be fully containerized using Docker microservices (Alert Engine, Dispatch Engine, EHR Engine) to support independent maintenance and scaling. |
| **C-NFR-09** | The system shall support automatic failover recovery with a Recovery Time Objective (RTO) of < 30 sec in the event of a primary node crash. |
