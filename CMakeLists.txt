cmake_minimum_required(VERSION 3.21)
project(avr128db48_project LANGUAGES C CXX ASM)

add_executable(firmware src/main.c)
set_target_properties(firmware PROPERTIES
    OUTPUT_NAME "${PROJECT_NAME}"
    SUFFIX ".elf"
    C_STANDARD 11
    CXX_STANDARD 17
)
target_compile_options(firmware PRIVATE
    -mmcu=avr128db48 -Wall -Wextra -ffunction-sections -fdata-sections
    $<IF:$<CONFIG:Debug>,-Og,-Os>
)
target_link_options(firmware PRIVATE -mmcu=avr128db48 -Wl,--gc-sections)
if(DEFINED ENV{MPT_AVR_LIBDIR})

    # Search the AVR128DB48 multilib before the wrapper's other AVR libraries.
    target_link_directories(firmware PRIVATE "$ENV{MPT_AVR_LIBDIR}")
endif()

find_program(AVR_OBJCOPY NAMES avr-objcopy REQUIRED)
set(hex "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.hex")
add_custom_command(OUTPUT "${hex}"
    COMMAND "${AVR_OBJCOPY}" -O ihex -R .eeprom $<TARGET_FILE:firmware> "${hex}"
    DEPENDS firmware
    VERBATIM
)
add_custom_target(firmware_hex ALL DEPENDS "${hex}")
