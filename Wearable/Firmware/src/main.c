#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"

// NimBLE Includes
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "services/gap/ble_svc_gap.h"

// Include Project Pinout & Config
#include "pin_config.h"

static const char *TAG = "AeroMedic_Firmware";

// دالة إعداد وبدء البث الإعلاني (BLE Advertising / Beacon)
void start_ble_advertising(void) {
    struct ble_gap_adv_params adv_params;
    struct ble_hs_adv_fields fields;
    int rc;

    memset(&fields, 0, sizeof(fields));

    // 1. تحديد أعلام البث (General Discovery + BLE Only)
    fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;

    // 2. إرفاق اسم الجهاز
    fields.name = (uint8_t *)BLE_DEVICE_NAME;
    fields.name_len = strlen(BLE_DEVICE_NAME);
    fields.name_is_complete = 1;

    // 3. تطبيق الإعدادات على حزمة البث
    rc = ble_gap_adv_set_fields(&fields);
    if (rc != 0) {
        ESP_LOGE(TAG, "Error setting BLE adv fields; rc=%d", rc);
        return;
    }

    // 4. ضبط معاملات التوقيت ونوع البث
    memset(&adv_params, 0, sizeof(adv_params));
    adv_params.conn_mode = BLE_GAP_CONN_MODE_UND; // Non-directed connectable
    adv_params.disc_mode = BLE_GAP_DISC_MODE_GEN; // General discoverable
    adv_params.itvl_min  = BLE_ADV_INTERVAL_MIN;  // 100 ms
    adv_params.itvl_max  = BLE_ADV_INTERVAL_MAX;  // 150 ms

    // 5. بدء البث الفعلي
    rc = ble_gap_adv_start(BLE_OWN_ADDR_PUBLIC, NULL, BLE_HS_FOREVER, &adv_params, NULL, NULL);
    if (rc != 0) {
        ESP_LOGE(TAG, "Error starting BLE advertising; rc=%d", rc);
        return;
    }

    ESP_LOGI(TAG, "BLE Beacon started broadcasting successfully: %s", BLE_DEVICE_NAME);
}

// دالة مزامنة مكدس البلوتوث عند الجاهزية
void on_ble_sync(void) {
    start_ble_advertising();
}

// مهمة FreeRTOS لتشغيل مكدس NimBLE في الخلفية
void nimble_host_task(void *param) {
    nimble_port_run();
    nimble_port_freertos_deinit();
}

void app_main(void) {
    esp_err_t ret;

    ESP_LOGI(TAG, "Initializing AeroMedic Wearable Firmware Skeleton...");

    // تهيئة ذاكرة NVS (ضرورية لعمل الراديو والبلوتوث)
    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // تهيئة وتشغيل مكدس NimBLE
    nimble_port_init();
    ble_hs_cfg.sync_cb = on_ble_sync;
    nimble_port_freertos_init(nimble_host_task);

    ESP_LOGI(TAG, "Firmware Skeleton ready. Sensors & FreeRTOS tasks to be added.");
}