#include <stdio.h>
#include <string.h>
#include <math.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "driver/i2c.h"
#include "driver/gpio.h"
#include "esp_sleep.h"

// NimBLE
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "services/gap/ble_svc_gap.h"

#include "pin_config.h"

#define AEROMEDIC_DEVICE_ID 0x00A1
#define MPU_ADDR            0x68
#define I2C_PORT            I2C_NUM_0

#define FLAG_FALL_DETECTED   (1 << 0)

// ألوان مخصصة للمراقبة عبر الطرفية
// تعريفات ANSI القياسية الصريحة
#define C_RESET   "\x1B[0m"
#define C_GRAY    "\x1B[90m"
#define C_YELLOW  "\x1B[33m"
#define C_CYAN    "\x1B[36m"
#define C_GREEN   "\x1B[32m"
#define C_RED     "\x1B[31m"

static volatile bool motionDetected = false;

#pragma pack(push, 1)
typedef struct {
    uint16_t device_id;
    uint8_t  seq_num;
    uint8_t  status_flags;
    uint8_t  heart_rate;
    uint8_t  spo2;
    uint8_t  body_temp_encoded;
} __attribute__((packed)) aeromedic_payload_t;
#pragma pack(pop)

static aeromedic_payload_t current_payload = {
    .device_id = AEROMEDIC_DEVICE_ID,
    .seq_num = 0,
    .status_flags = 0,
    .heart_rate = 75,
    .spo2 = 98,
    .body_temp_encoded = 65
};

// ================================================================
// بث الـ BLE في الخلفية بصمت تام
// ================================================================
void update_ble_payload(const aeromedic_payload_t *payload) {
    struct ble_hs_adv_fields fields;
    memset(&fields, 0, sizeof(fields));
    fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    fields.name = (uint8_t *)BLE_DEVICE_NAME;
    fields.name_len = strlen(BLE_DEVICE_NAME);
    fields.name_is_complete = 1;
    fields.mfg_data = (const uint8_t *)payload;
    fields.mfg_data_len = sizeof(aeromedic_payload_t);
    ble_gap_adv_set_fields(&fields);
}

void start_ble_advertising(void) {
    struct ble_gap_adv_params adv_params;
    update_ble_payload(&current_payload);
    memset(&adv_params, 0, sizeof(adv_params));
    adv_params.conn_mode = BLE_GAP_CONN_MODE_UND;
    adv_params.disc_mode = BLE_GAP_DISC_MODE_GEN;
    adv_params.itvl_min  = BLE_ADV_INTERVAL_MIN;
    adv_params.itvl_max  = BLE_ADV_INTERVAL_MAX;
    ble_gap_adv_start(BLE_OWN_ADDR_PUBLIC, NULL, BLE_HS_FOREVER, &adv_params, NULL, NULL);
}

void on_ble_sync(void) { start_ble_advertising(); }
void nimble_host_task(void *param) { nimble_port_run(); nimble_port_freertos_deinit(); }

// ================================================================
// دوال قراءة وكتابة المسجلات المطابقة لـ Wire
// ================================================================
static void writeRegister(uint8_t reg, uint8_t data) {
    uint8_t buf[2] = {reg, data};
    i2c_master_write_to_device(I2C_PORT, MPU_ADDR, buf, 2, pdMS_TO_TICKS(100));
}

static uint8_t readRegister(uint8_t reg) {
    uint8_t val = 0;
    i2c_master_write_read_device(I2C_PORT, MPU_ADDR, &reg, 1, &val, 1, pdMS_TO_TICKS(100));
    return val;
}

static void configureMPU6050_WOM(void) {
    writeRegister(0x6B, 0x80); vTaskDelay(pdMS_TO_TICKS(100));
    writeRegister(0x6B, 0x00); vTaskDelay(pdMS_TO_TICKS(10));
    writeRegister(0x1C, 0x11);
    writeRegister(0x1F, 10);   // حساسية حركة أعلى للاستيقاظ (~0.31g)
    writeRegister(0x20, 2);
    writeRegister(0x37, 0x20);
    writeRegister(0x38, 0x40);
    writeRegister(0x6C, 0x47);
    writeRegister(0x6B, 0x20);
    readRegister(0x3A);
}

static void wakeGyro(void) {
    writeRegister(0x6B, 0x00);
    writeRegister(0x6C, 0x00);
    vTaskDelay(pdMS_TO_TICKS(40));
}

static void putGyroToSleepWOM(void) {
    writeRegister(0x6C, 0x47);
    writeRegister(0x6B, 0x20);
    readRegister(0x3A);
}

static bool readSensorsDetailed(float *ax, float *ay, float *az, float *totalA, float *totalG) {
    uint8_t reg = 0x3B;
    uint8_t data[14];
    if (i2c_master_write_read_device(I2C_PORT, MPU_ADDR, &reg, 1, data, 14, pdMS_TO_TICKS(100)) != ESP_OK) {
        return false;
    }

    int16_t raw_ax = (data[0] << 8) | data[1];
    int16_t raw_ay = (data[2] << 8) | data[3];
    int16_t raw_az = (data[4] << 8) | data[5];
    int16_t raw_gx = (data[8] << 8) | data[9];
    int16_t raw_gy = (data[10] << 8) | data[11];
    int16_t raw_gz = (data[12] << 8) | data[13];

    *ax = (float)raw_ax / 4096.0f;
    *ay = (float)raw_ay / 4096.0f;
    *az = (float)raw_az / 4096.0f;
    *totalA = sqrtf((*ax) * (*ax) + (*ay) * (*ay) + (*az) * (*az));

    float gx_dps = (float)raw_gx / 65.5f;
    float gy_dps = (float)raw_gy / 65.5f;
    float gz_dps = (float)raw_gz / 65.5f;
    *totalG = sqrtf(gx_dps * gx_dps + gy_dps * gy_dps + gz_dps * gz_dps);

    if (isnan(*totalA)) *totalA = 1.0f;
    if (isnan(*totalG)) *totalG = 0.0f;
    return true;
}

static void IRAM_ATTR motion_isr(void* arg) {
    motionDetected = true;
}

// دالة محاكاة millis() الدقيقة
static inline uint32_t get_millis(void) {
    return (uint32_t)(esp_timer_get_time() / 1000ULL);
}

// ================================================================
// منطق كشف السقوط المطابق لكودك الأصلي تماماً
// ================================================================
void fall_detection_task(void *param) {
    while (1) {
        if (!motionDetected) {
            printf(C_GRAY "[SLEEP] ESP32 in Light Sleep. Monitoring motion...\n" C_RESET);
            fflush(stdout);
            esp_light_sleep_start();
        }

        if (motionDetected) {
            motionDetected = false;
            readRegister(0x3A);

            printf(C_YELLOW "\n[EVENT] Motion Trigger -> Waking Gyroscope...\n" C_RESET);
            fflush(stdout);
            wakeGyro();

            float ax, ay, az, totalA, totalG;
            float pre_ax = 0, pre_ay = 0, pre_az = 0;
            float peakImpact = 0.0f;
            float weightedGyro = 0.0f;
            float totalWeight = 0.0f;
            const float weights[5] = {2.5f, 2.2f, 1.8f, 1.4f, 1.0f};

            // 1. فحص الدوران المبكر
            for (int i = 0; i < 5; i++) {
                if (readSensorsDetailed(&ax, &ay, &az, &totalA, &totalG)) {
                    if (i == 0) { pre_ax = ax; pre_ay = ay; pre_az = az; }
                    weightedGyro += (totalG * weights[i]);
                    totalWeight += weights[i];
                    if (totalA > peakImpact) peakImpact = totalA;
                }
                vTaskDelay(pdMS_TO_TICKS(50));
            }
            float normGyro = (totalWeight > 0.0f) ? (weightedGyro / totalWeight) : 0.0f;

            // 2. تتبع ذروة الارتطام
            uint32_t t = get_millis();
            while ((get_millis() - t) < 500) {
                if (readSensorsDetailed(&ax, &ay, &az, &totalA, &totalG)) {
                    if (totalA > peakImpact) peakImpact = totalA;
                }
                vTaskDelay(pdMS_TO_TICKS(40));
            }

            // 3. حساب تغير زاوية الميلان (Tilt)
            vTaskDelay(pdMS_TO_TICKS(150));
            float post_ax = 0, post_ay = 0, post_az = 0;
            readSensorsDetailed(&post_ax, &post_ay, &post_az, &totalA, &totalG);

            float dot = (pre_ax * post_ax) + (pre_ay * post_ay) + (pre_az * post_az);
            float m1 = sqrtf(pre_ax * pre_ax + pre_ay * pre_ay + pre_az * pre_az);
            float m2 = sqrtf(post_ax * post_ax + post_ay * post_ay + post_az * post_az);
            float cosTheta = dot / (m1 * m2);
            if (cosTheta > 1.0f) cosTheta = 1.0f;
            if (cosTheta < -1.0f) cosTheta = -1.0f;
            float tiltAngle = acosf(cosTheta) * (180.0f / (float)M_PI);
            if (isnan(tiltAngle)) tiltAngle = 0.0f;

            // 4. فحص السكون اللاحق (Immobility)
            float sum = 0.0f, readings[8];
            for (int i = 0; i < 8; i++) {
                readSensorsDetailed(&ax, &ay, &az, &totalA, &totalG);
                readings[i] = totalA;
                sum += totalA;
                vTaskDelay(pdMS_TO_TICKS(80));
            }
            float mean = sum / 8.0f, varSum = 0.0f;
            for (int i = 0; i < 8; i++) {
                varSum += (readings[i] - mean) * (readings[i] - mean);
            }
            float immobilityVar = varSum / 8.0f;

            // التحقق من الشروط بنفس العتبات الأصلية
            bool passGyro   = (normGyro > 95.0f);
            bool passImpact = (peakImpact > 1.85f);
            bool passTilt   = (tiltAngle > 30.0f);
            bool passStill  = (immobilityVar < 0.15f);

            // طباعة سطر المقاييس باللون السماوي
            printf(C_CYAN "[METRICS] Gyro: %.1f dps | Impact: %.2fg | Tilt: %.1f deg | Stillness: %.4f\n" C_RESET,
                   normGyro, peakImpact, tiltAngle, immobilityVar);
            fflush(stdout);

            // النتيجة وتطبيق التجميد
            if (passGyro && passImpact && passTilt && passStill) {
                printf(C_RED ">>> [ALERT] FALL DETECTED! <<<\n");
                
                fflush(stdout);

                // تحديث حزمة الـ BLE
                current_payload.status_flags |= FLAG_FALL_DETECTED;
                current_payload.seq_num++;
                update_ble_payload(&current_payload);

                // تجميد 5 ثوانٍ
                vTaskDelay(pdMS_TO_TICKS(5000));

                current_payload.status_flags &= ~FLAG_FALL_DETECTED;
                update_ble_payload(&current_payload);

                printf(C_GREEN "[RESET] Resuming normal operation.\n\n" C_RESET);
                fflush(stdout);
            } else {
                printf(C_GREEN ">>> [DISMISSED] Normal Movement.\n\n" C_RESET);
                fflush(stdout);
            }

            putGyroToSleepWOM();

            // نافذة تهدئة لمنع تشغيل المقاطعة بسبب ارتداد اليد
            vTaskDelay(pdMS_TO_TICKS(350));
            readRegister(0x3A);
            motionDetected = false;
        }
    }
}

void app_main(void) {
    // كتم كل لوقات النظام والـ BLE
    esp_log_level_set("*", ESP_LOG_NONE);

    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    nimble_port_init();
    ble_hs_cfg.sync_cb = on_ble_sync;
    nimble_port_freertos_init(nimble_host_task);

    // تهيئة I2C
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = MPU6050_SDA_PIN,
        .scl_io_num = MPU6050_SCL_PIN,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = 400000
    };
    i2c_param_config(I2C_PORT, &conf);
    i2c_driver_install(I2C_PORT, conf.mode, 0, 0, 0);

    // تهيئة المقاطعة
    gpio_config_t io_conf = {
        .pin_bit_mask = (1ULL << MPU6050_INT_PIN),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_ENABLE,
        .intr_type = GPIO_INTR_POSEDGE
    };
    gpio_config(&io_conf);
    gpio_install_isr_service(0);
    gpio_isr_handler_add(MPU6050_INT_PIN, motion_isr, NULL);
    esp_sleep_enable_ext0_wakeup(MPU6050_INT_PIN, 1);

    printf(C_CYAN "\n--- AeroMedic Wearable Engine Ready ---\n" C_RESET);
    fflush(stdout);
    configureMPU6050_WOM();

    xTaskCreate(fall_detection_task, "fall_task", 4096, NULL, 6, NULL);
}