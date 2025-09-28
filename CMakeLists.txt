cmake_minimum_required(VERSION 3.22)

# Setup compiler settings
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

# Define the build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

# Set the project name
set(CMAKE_PROJECT_NAME press-command)

# Enable compile command to ease indexing with e.g. clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# Core project settings
project(${CMAKE_PROJECT_NAME} LANGUAGES C CXX ASM)
message("Build type: " ${CMAKE_BUILD_TYPE})

# Trick CMake into thinking compiler always works (for cross-compilation)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

# Enable ASM explicitly
enable_language(C ASM)

# Create executable
add_executable(${CMAKE_PROJECT_NAME})

add_compile_options(
        -mcpu=cortex-m4
        -mthumb
        -mfpu=fpv4-sp-d16
        -mfloat-abi=hard
)

# Add CubeMX generated sources
add_subdirectory(cmake/stm32cubemx)

# Toolchain directory (from C compiler path)
cmake_path(GET CMAKE_C_COMPILER PARENT_PATH ARM_TOOLCHAIN_DIR)

# CMSIS DSP library (optional, requires -DARM_CMSIS_PATH=/path/to/CMSIS)
if(DEFINED ARM_CMSIS_PATH)
    message(STATUS "Using CMSIS from ${ARM_CMSIS_PATH}")
    add_library(arm_ARMv8MMLldfsp_math STATIC IMPORTED)
    set_target_properties(arm_ARMv8MMLldfsp_math PROPERTIES
            IMPORTED_LOCATION "${ARM_CMSIS_PATH}/CMSIS/DSP/Lib/GCC/libarm_ARMv8MMLldfsp_math.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ARM_CMSIS_PATH}/CMSIS/Include"
    )
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE arm_ARMv8MMLldfsp_math)
endif()

# Include directories (add your Cube + BSP + CMSIS includes)
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
        ${CMAKE_SOURCE_DIR}/Core/Inc
        ${CMAKE_SOURCE_DIR}/Drivers/CMSIS/Device/ST/STM32L4xx/Include
        ${CMAKE_SOURCE_DIR}/Drivers/CMSIS/Include
        ${CMAKE_SOURCE_DIR}/Drivers/STM32L4xx_HAL_Driver/Inc
        # Add BSP/include dirs as needed
)

# Compile definitions (macros)
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
        USE_FULL_LL_DRIVER
        __USE_STM32__
        STM32L476xx
        HSE_VALUE=10000000
        HSE_STARTUP_TIMEOUT=100
        LSE_STARTUP_TIMEOUT=5000
        LSE_VALUE=32768
        EXTERNAL_CLOCK_VALUE=12288000
        HSI_VALUE=16000000
        LSI_VALUE=32000
        VDD_VALUE=3300
        PREFETCH_ENABLE=0
        INSTRUCTION_CACHE_ENABLE=1
        DATA_CACHE_ENABLE=1
        SUPPORT_TIME_NS=1
        "$<$<CONFIG:DEBUG>:DEBUG>"
        "$<$<CONFIG:DEBUG>:USE_ASSERT_FULL>"
)

# Compile options
target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE
        "-mcpu=cortex-m4"
        "-mfpu=fpv4-sp-d16"
        "-mfloat-abi=hard"
        "$<$<COMPILE_LANGUAGE:C>:-std=gnu11>"
        "$<$<COMPILE_LANGUAGE:C,CXX>:-Wall>"
        "$<$<COMPILE_LANGUAGE:C>:-fdata-sections>"
        "$<$<COMPILE_LANGUAGE:C>:-ffunction-sections>"
        "$<$<COMPILE_LANGUAGE:CXX>:-std=c++17>"
        "$<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>"
        "$<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>"
        "$<$<COMPILE_LANGUAGE:CXX>:-fno-threadsafe-statics>"
        "$<$<COMPILE_LANGUAGE:C,CXX>:-ffunction-sections>"
        "$<$<COMPILE_LANGUAGE:C,CXX>:-fdata-sections>"
        "$<$<COMPILE_LANGUAGE:C,CXX>:-Wno-sign-compare>"
        "$<$<COMPILE_LANGUAGE:C,CXX>:-fstack-usage>"
        "$<$<COMPILE_LANGUAGE:ASM>:-x>"
        "$<$<COMPILE_LANGUAGE:ASM>:assembler-with-cpp>"
        "$<$<COMPILE_LANGUAGE:ASM>:-MMD>"
        "$<$<COMPILE_LANGUAGE:ASM>:-MP>"
        "$<$<CONFIG:DEBUG>:-g3>"
        "$<$<CONFIG:DEBUG>:-O0>"
        "$<$<CONFIG:RELEASE>:-Os>"
        "$<$<CONFIG:RELEASE>:-g0>"
)

# Linker options
target_link_options(${CMAKE_PROJECT_NAME} PRIVATE
        "-mcpu=cortex-m4"
        "-mfpu=fpv4-sp-d16"
        "-mfloat-abi=hard"
        "-T${CMAKE_SOURCE_DIR}/STM32L476XX_FLASH.ld"
        "-Wl,-Map=${CMAKE_PROJECT_NAME}.map"
        "--specs=nano.specs"
        "-mthumb"
        "-Wl,--start-group"
        "-lc"
        "-lm"
        "-Wl,--end-group"
        "-Wl,--gc-sections"
        "-Wl,--print-memory-usage"
        "-static"
)

# Build artifact suffix
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES SUFFIX ".elf")

# Post-build commands
add_custom_command(
        TARGET ${CMAKE_PROJECT_NAME}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -h -S ${CMAKE_PROJECT_NAME}.elf > ${CMAKE_PROJECT_NAME}.list
        COMMENT "Generated *.list file")
add_custom_command(
        TARGET ${CMAKE_PROJECT_NAME}
        POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary ${CMAKE_PROJECT_NAME}.elf ${CMAKE_PROJECT_NAME}.bin
        COMMENT "Generated *.bin file")
add_custom_command(
        TARGET ${CMAKE_PROJECT_NAME}
        POST_BUILD
        COMMAND ${ARM_TOOLCHAIN_DIR}/arm-none-eabi-size ${CMAKE_PROJECT_NAME}.elf > ${CMAKE_PROJECT_NAME}.size
        COMMENT "Generated *.size file")
