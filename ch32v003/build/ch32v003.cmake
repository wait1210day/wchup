# SPDX-FileCopyrightText: 2026 masshiroio <masshirosora.io@gmail.com>
# SPDX-License-Identifier: MIT

include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/runtime.cmake")

# Sources and selected peripheral drivers are attached to this project target.
function(wch_add_executable target)
    cmake_parse_arguments(PARSE_ARGV 1 WCH "" "" "SOURCES;PERIPHERALS")
    if(WCH_UNPARSED_ARGUMENTS OR WCH_KEYWORDS_MISSING_VALUES OR NOT WCH_SOURCES)
        message(FATAL_ERROR "Usage: wch_add_executable(target SOURCES ... [PERIPHERALS gpio rcc ...])")
    endif()

    if(NOT WCH_SDK_DIR)
        message(FATAL_ERROR "Set WCH_SDK_DIR to the CH32V003 SDK directory")
    endif()
    set(sdk "${WCH_SDK_DIR}")

    add_executable(${target}
        ${WCH_SOURCES}
        "${sdk}/startup/startup_ch32v00x.S"
        "${sdk}/system/system_ch32v00x.c")
    foreach(peripheral IN LISTS WCH_PERIPHERALS)
        if(NOT peripheral MATCHES "^[a-z0-9_]+$")
            message(FATAL_ERROR "Invalid peripheral name: ${peripheral}")
        endif()
        set(driver "${sdk}/peripheral/src/ch32v00x_${peripheral}.c")
        if(NOT EXISTS "${driver}")
            message(FATAL_ERROR "Unknown CH32V003 peripheral: ${peripheral}")
        endif()
        target_sources(${target} PRIVATE "${driver}")
    endforeach()

    set_target_properties(${target} PROPERTIES
        SUFFIX .elf
        C_STANDARD 23
        C_STANDARD_REQUIRED YES
        C_EXTENSIONS NO)
    target_include_directories(${target} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include")
    target_include_directories(${target} SYSTEM PRIVATE
        "${sdk}/core" "${sdk}/peripheral/inc" "${sdk}/system")
    target_link_libraries(${target} PRIVATE wch_runtime)
    target_compile_options(${target} PRIVATE
        -march=rv32ec_zicsr_zifencei -mabi=ilp32e
        -ffreestanding -ffunction-sections -fdata-sections
        -Wall -Wextra)

    set(linker_script "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/link.ld")
    target_link_options(${target} PRIVATE
        -march=rv32ec_zicsr_zifencei -mabi=ilp32e -nostdlib
        "-T${linker_script}" -Wl,--gc-sections
        -Wl,--print-memory-usage)
    set_property(TARGET ${target} APPEND PROPERTY LINK_DEPENDS "${linker_script}")
endfunction()
