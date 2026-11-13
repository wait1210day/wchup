#!/bin/sh
# SPDX-FileCopyrightText: 2026 masshiroio <masshirosora.io@gmail.com>
# SPDX-License-Identifier: MIT

# Fetch the runtime sources pinned by this repository's submodule entries.
set -eu

cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

llvm_path=llvmlib/llvm-project
picolibc_path=llvmlib/picolibc

git submodule init -- "$llvm_path" "$picolibc_path"

# Prepare sparse checkout before submodule update can check out the LLVM tree.
# Reuse an existing clone, including one created by submodule update.
if [ ! -e "$llvm_path/.git" ]; then
    llvm_url=$(git config --get submodule.llvmlib/llvm-project.url)
    git clone --depth 1 --filter=blob:none --sparse --no-checkout \
        "$llvm_url" "$llvm_path"
fi
git -C "$llvm_path" sparse-checkout set --cone compiler-rt cmake llvm/cmake
git submodule absorbgitdirs -- "$llvm_path"
git submodule update --init --checkout --depth 1 --filter=blob:none -- "$llvm_path"
git submodule update --init --checkout --depth 1 -- "$picolibc_path"

git submodule status -- "$llvm_path" "$picolibc_path"
