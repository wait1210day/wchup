# SPDX-FileCopyrightText: 2026 masshiroio <masshirosora.io@gmail.com>
# SPDX-License-Identifier: MIT

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv32)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

find_program(CMAKE_C_COMPILER clang REQUIRED)
set(CMAKE_ASM_COMPILER "${CMAKE_C_COMPILER}")
set(CMAKE_C_COMPILER_TARGET riscv32-unknown-elf)
set(CMAKE_ASM_COMPILER_TARGET riscv32-unknown-elf)

find_program(CMAKE_LINKER ld.lld REQUIRED)
find_program(CMAKE_AR llvm-ar REQUIRED)
find_program(CMAKE_RANLIB llvm-ranlib REQUIRED)
set(CMAKE_EXE_LINKER_FLAGS_INIT "-fuse-ld=\"${CMAKE_LINKER}\"")
