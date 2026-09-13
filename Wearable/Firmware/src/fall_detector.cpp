#define EI_CLASSIFIER_DISABLE_ESP_DSP 1
#include "fall_detector.h"
#include <cmath>
#include <cstring>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/i2c.h"
#include "driver/gpio.h"
#include "esp_sleep.h"
#include "esp_log.h"
#include "pin_config.h"

// تضمين واجهة Edge Impulse
#include "edge-impulse-sdk/classifier/ei_run_classifier.h"

static const char *TAG = "FALL_ENGINE";

#define MPU_ADDR 0x68
#define I2C_PORT I2C_NUM_0

// كتابة مسجل I2C
static esp_err_t mpu_write_reg(uint8_t reg, uint8_t val) {
    uint8_t buf[2] = {reg, val};
    return i2c_master_write_to_device(I2C_PORT, MPU_ADDR, buf, 2, pdMS_TO_TICKS(100));
}

// قراءة مسجل I2C
static uint8_t mpu_read_reg(uint8_t reg) {
    uint8_t val = 0;
    i2c_master_write_read_device(I2C_PORT, MPU_ADDR, &reg, 1, &val, 1, pdMS_TO_TICKS(100));
    return val;
}

// قراءة محاور التسارع والجايرو في طلب I2C واحد
static bool read_sensors(float *ax, float *ay, float *az, float *totalA, float *totalG) {
    uint8_t reg = 0x3B;
    uint8_t data[14];
    esp_err_t ret = i2c_master_write_read_device(I2C_PORT, MPU_ADDR, &reg, 1, data, 14, pdMS_TO_TICKS(100));
    if (ret != ESP_OK) return false;

    int16_t raw_ax = (int16_t)((data[0] << 8) | data[1]);
    int16_t raw_ay = (int16_t)((data[2] << 8) | data[3]);
    int16_t raw_az = (int16_t)((data[4] << 8) | data[5]);
    int16_t raw_gx = (int16_t)((data[8] << 8) | data[9]);
    int16_t raw_gy = (int16_t)((data[10] << 8) | data[11]);
    int16_t raw_gz = (int16_t)((data[12] << 8) | data[13]);

    *ax = (float)raw_ax / 4096.0f;
    *ay = (float)raw_ay / 4096.0f;
    *az = (float)raw_az / 4096.0f;
    *totalA = sqrtf((*ax) * (*ax) + (*ay) * (*ay) + (*az) * (*az));

    float gx = (float)raw_gx / 65.5f;
    float gy = (float)raw_gy / 65.5f;
    float gz = (float)raw_gz / 65.5f;
    *totalG = sqrtf(gx * gx + gy * gy + gz * gz);

    if (std::isnan(*totalA)) *totalA = 1.0f;
    if (std::isnan(*totalG)) *totalG = 0.0f;
    return true;
}

static void wake_gyro(void) {
    mpu_write_reg(0x6B, 0x00);
    mpu_write_reg(0x6C, 0x00);
    vTaskDelay(pdMS_TO_TICKS(40));
}

void fall_detector_arm_sleep(void) {
    mpu_write_reg(0x6C, 0x47); // Gyro OFF
    mpu_write_reg(0x6B, 0x20); // Cycle Mode
    mpu_read_reg(0x3A);        // Clear interrupt latch
}

esp_err_t fall_detector_init(void) {
    // تهيئة منفذ I2C بصياغة متوافقة تماماً مع C++
    i2c_config_t conf;
    memset(&conf, 0, sizeof(i2c_config_t));
    conf.mode = I2C_MODE_MASTER;
    conf.sda_io_num = (gpio_num_t)MPU6050_SDA_PIN;
    conf.scl_io_num = (gpio_num_t)MPU6050_SCL_PIN;
    conf.sda_pullup_en = GPIO_PULLUP_ENABLE;
    conf.scl_pullup_en = GPIO_PULLUP_ENABLE;
    conf.master.clk_speed = 400000;

    i2c_param_config(I2C_PORT, &conf);
    i2c_driver_install(I2C_PORT, conf.mode, 0, 0, 0);

    // ضبط الـ Wake-on-Motion
    mpu_write_reg(0x6B, 0x80); vTaskDelay(pdMS_TO_TICKS(100));
    mpu_write_reg(0x6B, 0x00); vTaskDelay(pdMS_TO_TICKS(10));
    mpu_write_reg(0x1C, 0x11); // +-8g & High Pass Filter
    mpu_write_reg(0x1F, 10);   // Motion Threshold
    mpu_write_reg(0x20, 2);    // Motion Duration
    mpu_write_reg(0x37, 0x20); // Push-pull latch
    mpu_write_reg(0x38, 0x40); // Motion INT Enable
    
    fall_detector_arm_sleep();

    // تجهيز بن المقاطعة للاستيقاظ الخارجي
    gpio_config_t io_conf;
    memset(&io_conf, 0, sizeof(gpio_config_t));
    io_conf.pin_bit_mask = (1ULL << MPU6050_INT_PIN);
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    io_conf.pull_down_en = GPIO_PULLDOWN_ENABLE;
    io_conf.intr_type = GPIO_INTR_POSEDGE;
    gpio_config(&io_conf);
    
    esp_sleep_enable_ext0_wakeup((gpio_num_t)MPU6050_INT_PIN, 1);

    ESP_LOGI(TAG, "Fall Engine Initialized with WOM (Threshold = 10, Accel = 5Hz)");
    return ESP_OK;
}

bool fall_detector_run_analysis(fall_metrics_t *metrics) {
    mpu_read_reg(0x3A); // تفريغ بت المقاطعة
    wake_gyro();

    float ax = 0.0f, ay = 0.0f, az = 0.0f, totalA = 0.0f, totalG = 0.0f;
    float pre_ax = 0.0f, pre_ay = 0.0f, pre_az = 0.0f;
    float peakImpact = 0.0f;
    float weightedGyro = 0.0f, totalWeight = 0.0f;
    const float weights[5] = {2.5f, 2.2f, 1.8f, 1.4f, 1.0f};

    // 1. الدوران المبكر
    for (int i = 0; i < 5; i++) {
        if (read_sensors(&ax, &ay, &az, &totalA, &totalG)) {
            if (i == 0) { pre_ax = ax; pre_ay = ay; pre_az = az; }
            weightedGyro += (totalG * weights[i]);
            totalWeight += weights[i];
            if (totalA > peakImpact) peakImpact = totalA;
        }
        vTaskDelay(pdMS_TO_TICKS(50));
    }
    metrics->norm_gyro_dps = (totalWeight > 0.0f) ? (weightedGyro / totalWeight) : 0.0f;

    // 2. تتبع الصدمة
    TickType_t start_tick = xTaskGetTickCount();
    while ((xTaskGetTickCount() - start_tick) < pdMS_TO_TICKS(500)) {
        if (read_sensors(&ax, &ay, &az, &totalA, &totalG)) {
            if (totalA > peakImpact) peakImpact = totalA;
        }
        vTaskDelay(pdMS_TO_TICKS(40));
    }
    metrics->peak_impact_g = peakImpact;

    // 3. انقلاب الزاوية الثلاثية (Tilt)
    vTaskDelay(pdMS_TO_TICKS(150));
    float post_ax = 0.0f, post_ay = 0.0f, post_az = 0.0f;
    read_sensors(&post_ax, &post_ay, &post_az, &totalA, &totalG);

    float dot = (pre_ax * post_ax) + (pre_ay * post_ay) + (pre_az * post_az);
    float m1 = sqrtf(pre_ax * pre_ax + pre_ay * pre_ay + pre_az * pre_az);
    float m2 = sqrtf(post_ax * post_ax + post_ay * post_ay + post_az * post_az);
    float denom = m1 * m2;
    float cosTheta = (denom > 0.0001f) ? (dot / denom) : 1.0f;
    
    if (cosTheta > 1.0f) cosTheta = 1.0f;
    if (cosTheta < -1.0f) cosTheta = -1.0f;
    metrics->tilt_angle_deg = acosf(cosTheta) * (180.0f / (float)M_PI);
    if (std::isnan(metrics->tilt_angle_deg)) metrics->tilt_angle_deg = 0.0f;

    // 4. فحص السكون (Immobility)
    float sum = 0.0f, readings[8];
    for (int i = 0; i < 8; i++) {
        read_sensors(&ax, &ay, &az, &totalA, &totalG);
        readings[i] = totalA;
        sum += totalA;
        vTaskDelay(pdMS_TO_TICKS(80));
    }
    float mean = sum / 8.0f, varSum = 0.0f;
    for (int i = 0; i < 8; i++) {
        varSum += (readings[i] - mean) * (readings[i] - mean);
    }
    metrics->immobility_var = varSum / 8.0f;

    // فحص الشروط الهجينة
    bool passGyro   = (metrics->norm_gyro_dps > 95.0f);
    bool passImpact = (metrics->peak_impact_g > 1.85f);
    bool passTilt   = (metrics->tilt_angle_deg > 30.0f);
    bool passStill  = (metrics->immobility_var < 0.15f);

    metrics->is_fall_confirmed = (passGyro && passImpact && passTilt && passStill);

    fall_detector_arm_sleep();
    return metrics->is_fall_confirmed;
}