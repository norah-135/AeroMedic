file(GLOB_RECURSE EI_SRCS 
    "edge-impulse-sdk/*.cpp"
    "edge-impulse-sdk/*.c"
    "edge-impulse-sdk/*.cc"
    "model-parameters/*.cpp"
    "model-parameters/*.c"
    "tflite-model/*.cpp"
    "tflite-model/*.cc"
)

idf_component_register(
    SRCS ${EI_SRCS}
    INCLUDE_DIRS "." 
                 "edge-impulse-sdk" 
                 "edge-impulse-sdk/classifier"
                 "edge-impulse-sdk/dsp"
                 "edge-impulse-sdk/tensorflow"
                 "edge-impulse-sdk/porting"
                 "model-parameters" 
                 "tflite-model"
    REQUIRES esp_timer
)

target_compile_definitions(${COMPONENT_LIB} PUBLIC 
    EI_CLASSIFIER_DISABLE_ESP_DSP=1
)

target_compile_options(${COMPONENT_LIB} PRIVATE -w)