#!/bin/sh
# SPDX-FileCopyrightText: 2026 masshiroio <masshirosora.io@gmail.com>
# SPDX-License-Identifier: MIT

set -eux
cd "$(dirname "$0")"
CONFIG_DIR="${PWD}"
cd ../..

TARGET="rv32ec-ilp32e-nomalloc"

BUILD_DIR="${PWD}/build/${TARGET}"
INSTALL_DIR="${PWD}/install/${TARGET}"
CROSS_FILE="${BUILD_DIR}/picolibc-cross.ini"

cmake -S llvm-project/compiler-rt/lib/builtins \
    -B "${BUILD_DIR}/compiler_rt" \
    -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="${CONFIG_DIR}/toolchain.cmake" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DLLVM_RUNTIMES_BUILD=ON \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
    -DCOMPILER_RT_BAREMETAL_BUILD=ON \
    -DCOMPILER_RT_BUILTINS_ENABLE_PIC=OFF \
    -DCOMPILER_RT_INCLUDE_TESTS=OFF

cmake --build "${BUILD_DIR}/compiler_rt" -j 4

mkdir -p "${INSTALL_DIR}/lib"

cp "${BUILD_DIR}/compiler_rt/lib/generic/libclang_rt.builtins-riscv32.a" "${INSTALL_DIR}/lib/"

# Keep the cross configuration and runtime path in sync with this build target.
cat > "${CROSS_FILE}" <<EOF
[binaries]
c = ['clang', '--target=riscv32-unknown-elf']
c_ld = 'lld'
ar = 'llvm-ar'
strip = 'llvm-strip'

[host_machine]
system = 'none'
cpu_family = 'riscv32'
cpu = 'rv32e'
endian = 'little'

[properties]
needs_exe_wrapper = true
has_link_defsym = true
librt = '${INSTALL_DIR}/lib/libclang_rt.builtins-riscv32.a'

[built-in options]
c_args = ['-march=rv32ec_zicsr_zifencei', '-mabi=ilp32e', '-ffreestanding', '-fno-strict-aliasing', '-ffunction-sections', '-fdata-sections']
c_link_args = ['-march=rv32ec_zicsr_zifencei', '-mabi=ilp32e', '-nostdlib']
EOF

meson setup --reconfigure "${BUILD_DIR}/picolibc" picolibc \
    --cross-file "${CROSS_FILE}" \
    --prefix "${INSTALL_DIR}" \
    --libdir lib \
    --buildtype minsize \
    -Dmultilib=false \
    -Dpicocrt=false \
    -Dpicocrt-lib=false \
    -Dsemihost=false \
    -Dtests=false \
    -Dthread-local-storage=false \
    -Dnewlib-global-errno=true \
    -Dstdio-locking=false \
    -Datomic-ungetc=false \
    -Dformat-default=integer \
    -Dio-long-long=false \
    -Dio-long-double=false \
    -Dspecsdir=none \
    -Denable-malloc=false \
    -Db_lto=false

meson compile -C "${BUILD_DIR}/picolibc" -j 4
meson install -C "${BUILD_DIR}/picolibc" --no-rebuild

mkdir -p "${INSTALL_DIR}/share/licenses"
cp llvm-project/compiler-rt/LICENSE.TXT "${INSTALL_DIR}/share/licenses/compiler_rt.txt"
cp picolibc/COPYING.picolibc "${INSTALL_DIR}/share/licenses/picolibc.txt"
