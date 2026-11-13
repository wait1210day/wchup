# CH32V003 SDK Snapshot

Source: https://github.com/openwch/ch32v003

Upstream commit: `4e1b7437ada5d3ae8831a6f4b811a6320e4e23c7`

## File Sources

- `core/`, `peripheral/`, `startup/`, and `debug/` are sourced from `Core/`, `Peripheral/`, `Startup/`, and `Debug/` under `EVT/EXAM/SRC/`, respectively.
- The build resource `link.ld` is sourced from `EVT/EXAM/SRC/Ld/Link.ld`.
- `system/system_ch32v00x.c` and `.h` are sourced from `EVT/EXAM/GPIO/GPIO_Toggle/User/`, providing reusable system clock initialization code.
- `docs/readme.md` is sourced from `Datasheet/README_zh.md`, retaining official download links to the chip datasheet, reference manual, and QingKe V2 processor core manual.

The directory structure was reorganized, and the build resource `link.ld` was modified: a separate `STACK` region was carved out from the top of the 2 KB SRAM, controlled by `__stack_size` (default: 256 B), with the remaining space allocated to `RAM`. Original stack and heap boundary symbols are retained. For local modifications made to the SDK, see below. Git repository history, example projects, duplicate SDK copies, evaluation board hardware files, dedicated applications, Windows tools, and their accompanying documentation have been removed.

## Usage Notes

`peripheral/` retains the complete set of peripheral drivers; projects compile the corresponding source files as needed.
`debug/` is an optional helper library for delay functions and UART/SDI `printf`, and is not required for attaching a debugger.
Projects provide their own `ch32v00x_conf.h`; in generated projects, this configuration resides in `include/`.

`startup/startup_ch32v00x.S` directly changes the INTSYSCR configuration from `0x3` to `0x2`:
disabling hardware auto-stacking while retaining interrupt nesting to accommodate Clang's standard interrupt handling.
`system/system_ch32v00x.c` changes the default system clock from HSE 48 MHz to HSI 48 MHz.
All other retained SDK source files are unmodified. CMake compiles these files directly.

## Copyright and Usage Restrictions

The original WCH copyright and usage restriction notices in each source file are preserved. Upstream source files state that the software (original or modified) and its binaries are intended for use with microcontrollers manufactured by Nanjing Qinheng Microelectronics. Refer to the original notices in individual files for exact terms.

## Location in Project Copies

In the wchup resource tree, the linker script and CMake modules reside in the sibling `build/` directory; when generating a standalone project, they are copied into the project's `cmake/` directory, while the SDK is copied into `third_party/ch32v003/`.
