## 🔄 2. Concept of Operations (ConOps)
This section outlines the operational framework, stakeholder roles, and deployment lifecycle of the AeroMedic system. It defines how the system functions in real-world environments from initial onboarding to emergency execution.

### 2.1 Operational Stakeholders & User Roles
To ensure seamless execution, the system architecture maps to three core operational stakeholders:

* **The Patient:** Wears the smart wristband, which locally monitors vital signs and fall-detection telemetry.
* **The Bystander / Responder:** The individual physically present at the emergency scene who interacts with the arrived drone payload box, following visual displays and live medical audio to administer the critical payload.
* **The Emergency Physician:** Accesses the centralized cloud management dashboard to monitor critical telemetry incoming during an active alert and remotely oversees the autonomous drone dispatch logic.

### 2.2 Core Operational Lifecycle Scenarios

#### Scenario A: Device Onboarding and Lifecycle Maintenance (The Binding Flow)
1. **Patient Registration:** The patient enters clinical profiles and emergency contact details through the application interface, creating an entry in the cloud database where the wearable device field remains empty.
2. **Hardware Authentication:** The patient powers on the smart wristband, which begins broadcasting its unique hardware ID via non-connecting BLE advertisement packets.
3. **Proximity Binding:** The mobile application detects the nearby advertisement packet, captures the hardware identifier, and patches the cloud database to bind the specific wristband to the patient record once.
4. **Predictive Maintenance:** The wristband wakes up intermittently (every 12 hours or when battery drops below 20%) to publish a brief maintenance packet to the cloud backend, enabling proactive device health tracking and failure prediction.

#### Scenario B: Critical Emergency Detection and Autonomous Dispatch
1. **Incident Trigger:** The wristband detects a critical health threshold or a severe fall using embedded IMU streams, passing an alert packet locally to the application, or via long-range LoRa links if cellular infrastructure is missing.
2. **Cloud Orchestration & Verification:** The cloud infrastructure intercepts the alert, automatically cross-references the patient's authenticated electronic health records (EHR) to verify payload compatibility, and approves dispatch.
3. **Flight Execution:** The system injects the target coordinate parameters into the autopilot environment, launching the autonomous drone to deliver the payload box to the precise emergency site within 5 minutes.
4. **Scene Integration:** The container unlocks via proximity ESP-NOW hardware authentication or a physician's remote cloud command. As an absolute fail-safe, if all network communications drop and the system becomes completely unresponsive, the container triggers an automatic timeout unlock to guarantee medical access. Simultaneously, a WebRTC audio/video link is launched to assist the bystander.

### 2.3 Operational Constraints
* **Regulatory Airspace:** The drone dispatch sequence must comply with local civilian aviation regulations and respect strict no-fly zones mapped in the autopilot mission parameters.
* **Power & Logistics:** The smart payload box must remain physically locked and low-powered until the autonomous drone confirms a safe arrival at the landing waypoint.

### 2.4 Functional Emergency Response Pathways (Modes of Activation)
To guarantee system availability under all environmental and user conditions, the architecture supports four distinct multi-layered emergency response pathways. Each path cuts through the functional layers from source to execution as detailed below:

#### Path 1: Automatic Wearable Device Pathway (The Primary Autonomous Link)
* **Source Layer:** The smart wristband automatically detects a critical biomedical anomaly or fall event.
* **Transport Layer:** Telemetry is transmitted locally via BLE to the patient's Mobile Application, which appends precise GPS coordinates and network timestamps, pushing the bundle via 5G/4G cellular links.
* **Cloud & Logic Layer:** The centralized Cloud core performs a fail-safe check, queries the nearest available drone station, and issues a structured Takeoff Order.
* **Execution Layer:** The targeted Drone Station processes the API Takeoff Order, launching the autonomous drone to deliver the medical payload to the location while providing continuous monitoring.

#### Path 2: LoRa Fail-Safe Wearable Device Pathway
* **Source Layer:** The smart wristband triggers an emergency alert in a rugged or remote mountain region lacking cellular coverage (or if the App didn’t send an ack).
* **Transport Layer:** The wristband broadcasts compressed emergency packets over long distances via LoRa directly to a local AeroMedic Ground Station Gateway.
* **Cloud & Logic Layer:** The Cloud core ingests the ground station payload, validates the incident location, and computes flight trajectories.
* **Execution Layer:** The drone is dispatched immediately, operating on a hardened communication loop to ensure secure delivery.

#### Path 3: Manual User App Pathway (The Direct On-Demand Link)
* **Source Layer:** The patient remains conscious but distressed and manually triggers the panic command via the application UI.
* **Transport Layer:** The request is routed instantly through 5G/4G protocols, attaching real-time mobile GPS positioning alongside the patient’s stored core profile data.
* **Cloud & Logic Layer:** The Cloud orchestrator bypassing automated sensor evaluation, immediately proceeding to flight clearance and station allocation.
* **Execution Layer:** The Takeoff Order is dispatched to the drone station for immediate launch and payload distribution.

#### Path 4: Voice Call User Pathway (The Legacy Fail-Safe Link)
* **Source Layer:** A bystander with no technical onboarding or access to the AeroMedic application encounters the incident and initiates a standard voice call via phone.
* **Transport Layer:** The emergency dispatcher intercepts the voice call over regular telecom networks and inputs the verbal location and patient details into the central Emergency Application platform, routing it via 5G/4G.
* **Cloud & Logic Layer:** The Cloud backend ingests the manually entered dispatcher parameters, registers it as a verified emergency, and schedules the flight logic.
* **Execution Layer:** The system triggers the drone station takeoff order, bringing the critical payload to the caller's verified location.