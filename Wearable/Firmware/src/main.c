#include <stdio.h>
#include <string.h>
#include <math.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "driver/gpio.h"
#include "esp_sleep.h"

// تضمين محرك كشف السقوط المدمج به Edge Impulse
#include "fall_detector.h"

// NimBLE
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "services/gap/ble_svc_gap.h"

#include "pin_config.h"

#define AEROMEDIC_DEVICE_ID 0x00A1
#define FLAG_FALL_DETECTED   (1 << 0)

// تعريف ألوان المراقبة
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
// بث الـ BLE
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

static void IRAM_ATTR motion_isr(void* arg) {
    motionDetected = true;
}

// ================================================================
// مهمة كشف السقوط باستخدام محرك Edge Impulse
// ================================================================
void fall_detection_task(void *param) {
    fall_metrics_t metrics;

    while (1) {
        if (!motionDetected) {
            printf(C_GRAY "[SLEEP] ESP32 in Light Sleep. Monitoring motion...\n" C_RESET);
            fflush(stdout);
            
            fall_detector_arm_sleep();
            esp_light_sleep_start();
        }

        if (motionDetected) {
            motionDetected = false;

            printf(C_YELLOW "\n[EVENT] Motion Trigger -> Invoking Edge Impulse Engine...\n" C_RESET);
            fflush(stdout);

            bool is_fall = fall_detector_run_analysis(&metrics);

            printf(C_CYAN "[METRICS] Gyro: %.1f dps | Impact: %.2fg | Tilt: %.1f deg | Stillness: %.4f\n" C_RESET,
                   metrics.norm_gyro_dps, metrics.peak_impact_g, metrics.tilt_angle_deg, metrics.immobility_var);
            fflush(stdout);

            if (is_fall) {
                printf(C_RED "    [ALERT] FALL CONFIRMED    \n" C_RESET);
                fflush(stdout);

                current_payload.status_flags |= FLAG_FALL_DETECTED;
                current_payload.seq_num++;
                update_ble_payload(&current_payload);

                vTaskDelay(pdMS_TO_TICKS(5000));

                current_payload.status_flags &= ~FLAG_FALL_DETECTED;
                update_ble_payload(&current_payload);

                printf(C_GREEN "[RESET] Resuming normal operation.\n\n" C_RESET);
                fflush(stdout);
            } else {
                printf(C_GREEN "    [DISMISSED] Normal Movement.\n\n" C_RESET);
                fflush(stdout);
            }

            // فترة تهدئة لتجنب القراءات الارتدادية
            vTaskDelay(pdMS_TO_TICKS(350));
            motionDetected = false;
        }
    }
}

void app_main(void) {
    // تفعيل اللوق لرؤية نتائج Edge Impulse
    esp_log_level_set("*", ESP_LOG_INFO);

    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    nimble_port_init();
    ble_hs_cfg.sync_cb = on_ble_sync;
    nimble_port_freertos_init(nimble_host_task);

    // تهيئة محرك السقوط والحساس
    fall_detector_init();

    // ربط معالج المقاطعة بأمان
    gpio_install_isr_service(0);
    gpio_isr_handler_add((gpio_num_t)MPU6050_INT_PIN, motion_isr, NULL);

    printf(C_CYAN "\n--- AeroMedic Wearable Engine Ready ---\n" C_RESET);
    fflush(stdout);

    // 8192 بايت لتفادي Stack Overflow أثناء تشغيل التنبؤ
    xTaskCreate(fall_detection_task, "fall_task", 8192, NULL, 6, NULL);
}