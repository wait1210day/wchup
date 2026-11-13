#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 masshiroio <masshirosora.io@gmail.com>
# SPDX-License-Identifier: MIT

"""Manage WCH projects with chip-specific SDKs and build resources."""

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent


@dataclass
class ChipInfo:
    resource_path: Path
    openocd_config: Path
    runtime_name: str


CHIP_INFO: dict[str, ChipInfo] = {
    'ch32v003': ChipInfo(
        resource_path=ROOT / 'ch32v003',
        openocd_config=ROOT / 'openocd-wch/bin/wch-riscv.cfg',
        runtime_name='rv32ec-ilp32e-nomalloc'
    )
}

OPENOCD = ROOT / "openocd-wch/bin/openocd"


def create_project(chip: str, name: str) -> Path:
    destination = Path.cwd() / name
    if destination.exists() or destination.is_symlink():
        raise FileExistsError(f"Destination already exists; refusing to overwrite: {destination}")

    info = CHIP_INFO[chip]
    resources = info.resource_path
    runtime = ROOT / "llvmlib/install" / info.runtime_name
    # Stage on the same filesystem; failed generation leaves no partial project.
    with tempfile.TemporaryDirectory(prefix=".wchup_", dir=Path.cwd()) as temporary:
        staging = Path(temporary) / name

        # Create basic project directory from template
        shutil.copytree(resources / "build/template", staging)

        # WCH sdk, to `//third_party/sdk`
        shutil.copytree(resources / "sdk", staging / "third_party" / chip)

        # `//cmake` directory
        cmake = staging / "cmake"
        cmake.mkdir()
        for filename in (f"{chip}.cmake", "link.ld"):
            shutil.copy2(resources / "build" / filename, cmake / filename)
        shutil.copy2(resources / "build/riscv-clang.cmake", cmake / "riscv-clang.cmake")
        shutil.copy2(
            ROOT / "llvmlib/configs" / info.runtime_name / "runtime.cmake",
            cmake / "runtime.cmake",
        )

        # `//third_party/runtime`, includes compiler-rt and picolib
        runtime_destination = staging / "third_party/runtime" / info.runtime_name
        shutil.copytree(runtime / "include", runtime_destination / "include")
        shutil.copytree(runtime / "share/licenses", runtime_destination / "share/licenses")
        (runtime_destination / "lib").mkdir()
        for filename in ("libc.a", "libclang_rt.builtins-riscv32.a"):
            shutil.copy2(runtime / "lib" / filename, runtime_destination / "lib" / filename)

        # CMakeLists
        template = staging / "CMakeLists.txt.in"
        (staging / "CMakeLists.txt").write_text(
            template.read_text(encoding="utf-8").replace("@PROJECT_NAME@", name),
            encoding="utf-8",
        )

        template.unlink()
        staging.rename(destination)

    return destination


def run_openocd(chip: str, *extra_args: str) -> int:
    try:
        return subprocess.run(
            [str(OPENOCD), "-f", str(CHIP_INFO[chip].openocd_config), *extra_args],
        ).returncode
    except OSError as error:
        print(f"OpenOCD failed: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


def flash_firmware(chip: str, elf: Path) -> int:
    elf = elf.resolve()
    if not elf.is_file():
        print(f"ELF file not found: {elf}", file=sys.stderr)
        return 1
    # Quote a single Tcl argument, including paths with spaces or Tcl metacharacters.
    path = str(elf).replace("\\", "\\\\")
    for character in ('"', "$", "[", "]"):
        path = path.replace(character, "\\" + character)
    path = path.replace("\n", "\\n").replace("\r", "\\r")
    return run_openocd(chip, "-c", f'program "{path}" verify reset exit')


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage WCH projects")
    parser.add_argument("--chip", required=True, choices=CHIP_INFO, help="Chip model")
    commands = parser.add_subparsers(dest="command", required=True)
    create_parser = commands.add_parser("create", help="Create a standalone CMake project with a copied SDK")
    create_parser.add_argument("project_name", help="New directory name under the current directory; letters, digits and underscores")
    commands.add_parser("openocd", help="Run the OpenOCD server in the foreground")
    flash_parser = commands.add_parser("flash", help="Program, verify and reset the target using OpenOCD")
    flash_parser.add_argument("elf", type=Path, help="Path to the ELF firmware file")
    args = parser.parse_args()
    if args.command == "openocd":
        return run_openocd(args.chip)
    if args.command == "flash":
        return flash_firmware(args.chip, args.elf)
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", args.project_name):
        create_parser.error("Project names must start with a letter or underscore and contain only letters, digits and underscores")
    try:
        destination = create_project(args.chip, args.project_name)
    except OSError as error:
        print(f"Creation failed: {error}", file=sys.stderr)
        return 1
    print(f"Created {destination}, to build this project:")
    print(f"  cd {args.project_name}")
    print("  cmake --preset release")
    print("  cmake --build --preset release")
    return 0


if __name__ == "__main__":
    sys.exit(main())
