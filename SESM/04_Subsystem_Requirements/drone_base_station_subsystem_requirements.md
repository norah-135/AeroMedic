# 4.6 Drone Base Station Subsystem Requirements

## 4.6.1 Overview & System Description

The Drone Base Station is the ground charging hub and communication center for the AeroMedic system. It protects the drone from harsh weather and keeps it fully charged and ready for emergency deployment at all times. The station acts as a communication bridge, supporting both LoRa for long-range signals and Cellular (4G/5G) networks.

### Why is the Base Station split into two types?
The station is divided into two operational types based on location, power supply, and network availability:

* **Distance vs. Connectivity:** When a patient is located far away in mountainous areas, public electricity and cellular coverage are usually weak or non-existent. Conversely, in areas closer to community centers and government buildings, continuous electrical power and mobile networks are readily available.
* **Smart Coverage Strategy:** stations are deployed on government building rooftops further out in rural centers, as well as on remote mountain peaks to cover hard-to-reach areas.

---

### 1. Off-Grid Mountain Station
* **Location:** Deployed on remote mountain peaks with no power grid or cellular infrastructure.
* **Power Source:** A hybrid renewable system combining solar panels and a 360° vertical-axis wind turbine (VAWT) that operates even in low winds with an IP67 dust/waterproof generator.
* **Station Battery:** Contains a large battery buffer with $3 \times$ the capacity of the drone battery to guarantee continuous fast-charging even without sun or wind.
* **Drone Charging Method:** Direct conductive charging for high energy efficiency (>95%).

---

### 2. On-Grid Station
* **Location:** Installed on rooftops of local government buildings in rural towns and villages.
* **Power Source:** Connected directly to the public electricity grid 220 V.
* **Station Battery:** Equipped with a compact backup battery (UPS) to keep the station running temporarily during power cuts.
* **Drone Charging Method:** Contactless inductive wireless charging for easy, weather-sealed alignment and docking.
