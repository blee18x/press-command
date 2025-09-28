set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_C_COMPILER /Applications/ArmGNUToolchain/14.3.rel1/arm-none-eabi/bin/arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER /Applications/ArmGNUToolchain/14.3.rel1/arm-none-eabi/bin/arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER})

# Don’t try to run test executables on host
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
