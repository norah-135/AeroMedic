#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

// مصفوفة الحالة المرجعة بعد انتهاء التحليل
typedef struct {
    float norm_gyro_dps;
    float peak_impact_g;
    float tilt_angle_deg;
    float immobility_var;
    bool  is_fall_confirmed;
} fall_metrics_t;

// دوال التحكم بمحرك السقوط
esp_err_t fall_detector_init(void);
bool fall_detector_run_analysis(fall_metrics_t *metrics);
void fall_detector_arm_sleep(void);

#ifdef __cplusplus
}
#endif