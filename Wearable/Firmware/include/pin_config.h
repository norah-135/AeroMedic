#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// ========================================================
// 1. MAX30102 Pulse Oximeter (I2C Bus)
// ========================================================
#define PIN_MAX30102_SDA          8    // Data -> GPIO8
#define PIN_MAX30102_SCL          9    // Clock -> GPIO9
#define PIN_MAX30102_INT          20   // Interrupt -> GPIO20
#define MAX30102_I2C_ADDR         0x57 // Fixed I2C Address

// ========================================================
// 2. MPU6050 6-Axis IMU (I2C Bus)
// ========================================================
#define MPU6050_SDA_PIN           21
#define MPU6050_SCL_PIN           22
#define MPU6050_INT_PIN           4

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