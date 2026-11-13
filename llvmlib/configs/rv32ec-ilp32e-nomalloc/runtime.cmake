# SPDX-FileCopyrightText: 2026 masshiroio <masshirosora.io@gmail.com>
# SPDX-License-Identifier: MIT

include_guard(GLOBAL)

# This module is copied into the generated project's cmake directory.
set(runtime_dir "${CMAKE_CURRENT_LIST_DIR}/../third_party/runtime/rv32ec-ilp32e-nomalloc")

add_library(wch_builtins STATIC IMPORTED GLOBAL)
set_target_properties(wch_builtins PROPERTIES
    IMPORTED_LOCATION "${runtime_dir}/lib/libclang_rt.builtins-riscv32.a")

add_library(wch_libc STATIC IMPORTED GLOBAL)
set_target_properties(wch_libc PROPERTIES
    IMPORTED_LOCATION "${runtime_dir}/lib/libc.a"
    INTERFACE_LINK_LIBRARIES wch_builtins)

add_library(wch_runtime INTERFACE)
target_include_directories(wch_runtime SYSTEM INTERFACE "${runtime_dir}/include")
target_link_libraries(wch_runtime INTERFACE wch_libc)
unset(runtime_dir)
