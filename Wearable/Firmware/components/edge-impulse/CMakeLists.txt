# تجميع كافة ملفات الكود بما فيها محرك esp-dsp الداخلي
file(GLOB_RECURSE EI_SRCS 
    "edge-impulse-sdk/*.cpp"
    "edge-impulse-sdk/*.c"
    "edge-impulse-sdk/*.cc"
    "model-parameters/*.cpp"
    "model-parameters/*.c"
    "tflite-model/*.cpp"
    "tflite-model/*.cc"
)

# مسار esp-dsp
set(ESP_DSP_DIR "${CMAKE_CURRENT_LIST_DIR}/edge-impulse-sdk/porting/espressif/esp-dsp")

idf_component_register(
    SRCS ${EI_SRCS}
    INCLUDE_DIRS "." 
                 "edge-impulse-sdk" 
                 "edge-impulse-sdk/classifier"
                 "edge-impulse-sdk/dsp"
                 "edge-impulse-sdk/dsp/dsp_engines"
                 "edge-impulse-sdk/tensorflow"
                 "edge-impulse-sdk/porting"
                 "model-parameters" 
                 "tflite-model"
                 "${ESP_DSP_DIR}/modules/common/include"
                 "${ESP_DSP_DIR}/modules/dotprod/include"
                 "${ESP_DSP_DIR}/modules/fft/include"
                 "${ESP_DSP_DIR}/modules/iir/include"
                 "${ESP_DSP_DIR}/modules/fir/include"
                 "${ESP_DSP_DIR}/modules/math/include"
                 "${ESP_DSP_DIR}/modules/matrix/include"
    REQUIRES esp_timer
)

target_compile_options(${COMPONENT_LIB} PRIVATE -w)