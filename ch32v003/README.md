## CH32V003 Architecture & Adaptations

The CH32V003 is a low-cost microcontroller featuring a QingKe V2 RISC-V core with 16 KB Flash and 2 KB SRAM. `wchup` implements several crucial adjustments to ensure stability under standard toolchains:

### Interrupts without Hardware Auto-Stacking

WCH's default startup code sets `INTSYSCR` (CSR `0x804`) to `0x3`, enabling hardware register auto-stacking on interrupt entry. This mechanism expects specific code generation supported only by WCH's proprietary GCC fork (`__attribute__((interrupt("WCH-Interrupt-fast")))`). Standard Clang emits conventional RISC-V software register saving routines on `__attribute__((interrupt))`.

`wchup` configures `INTSYSCR` to `0x2` in `startup_ch32v00x.S`. This retains hardware interrupt nesting while disabling hardware auto-stacking, allowing standard Clang interrupt handlers to function correctly.

### Default Clock Configuration

`system_ch32v00x.c` is configured by default to use the internal high-speed oscillator (HSI) multiplied via PLL to 48 MHz (`SYSCLK_FREQ_48MHZ_HSI`). An external crystal oscillator (HSE) is not required for operation out of the box.

### Memory Layout and Stack Separation

The linker script (`link.ld`) allocates a dedicated `STACK` region at the top of the 2 KB SRAM. The stack size is determined by `__stack_size` (default: 256 bytes), while the remaining 1792 bytes are allocated to `RAM` (`.data`, `.bss`, and `.highcode`).
