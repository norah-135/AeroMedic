#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// ========================================================
// 1. MAX30102 Pulse Oximeter (I2C Bus)
// ========================================================
#define PIN_MAX30102_SDA          8    // Data -> GPIO8
#define PIN_MAX30102_SCL          9    // Clock -> GPIO9
#define PIN_MAX30102_INT          20    // Interrupt -> GPIO7
#define MAX30102_I2C_ADDR         0x57 // Fixed I2C Address

// ========================================================
// 2. ICM-42688-P 6-Axis IMU (SPI Bus)
// ========================================================
#define PIN_ICM42688_MOSI         6    // Data In (AP_SDI) -> GPIO6
#define PIN_ICM42688_SCLK         4    // Clock (AP_SCLK) -> GPIO4
#define PIN_ICM42688_CS           10   // Chip Select (AP_CS) -> GPIO10
#define PIN_ICM42688_INT          21   // Interrupt (INT1) -> GPIO21

// ========================================================
// 3. Semtech SX1262 LoRa Transceiver (SPI & Control Pins)
// ========================================================
// SPI Bus
#define PIN_LORA_SCK              4    
#define PIN_LORA_MISO             5    
#define PIN_LORA_MOSI             6   
#define PIN_LORA_NSS              7    

// Control & Interrupt Lines
#define PIN_LORA_RESET            3    
#define PIN_LORA_BUSY             2   
#define PIN_LORA_DIO1             10   // Digital I/O 1 (IRQ / Event)

// Default RF Parameters
#define LORA_FREQUENCY_HZ         868000000 
#define LORA_BANDWIDTH_KHZ        125.0    
#define LORA_SPREADING_FACTOR     12         
#define LORA_TX_POWER_DBM         22       

// ========================================================
// 4. BLE Beacon Configuration (Proximity & Broadcast)
// ========================================================
#define BLE_DEVICE_NAME           "AeroMedic-Wearable"
#define BLE_ADV_INTERVAL_MIN      0x00A0    // 100 ms 
#define BLE_ADV_INTERVAL_MAX      0x00F0    // 150 ms

#ifdef __cplusplus
}
#endif
