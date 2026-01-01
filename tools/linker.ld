/****************************************************************************
 * RISC-V Linker Script for MonoCycleCPU
 *
 * Memory Layout:
 * - ROM (Instruction): 0x0000_0000 - 0x0000_0FFF (4KB, 1024 instructions)
 * - RAM (Data):        0x0000_0000 - 0x0000_0FFF (4KB)
 * - Frame Buffer:      0x8000_0000 - 0x8007_7FFF (480KB)
 * - Peripherals:       0x0000_1000 - 0x0000_100F
 ****************************************************************************/

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    /* Instruction ROM - 4KB */
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K

    /* Data RAM - 4KB */
    RAM (rw)  : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
    /* Code section - stored in ROM */
    .text : {
        *(.text.init)           /* Startup code first */
        *(.text)                /* Program code */
        *(.text.*)
        *(.rodata)              /* Read-only data */
        *(.rodata.*)
        . = ALIGN(4);
    } > ROM

    /* Data section - will be in RAM */
    .data : {
        _data_start = .;
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
        . = ALIGN(4);
        _data_end = .;
    } > RAM AT > ROM

    _data_load = LOADADDR(.data);

    /* Global pointer (simplified - point to start of data section) */
    PROVIDE(__global_pointer$ = _data_start);

    /* BSS section - uninitialized data in RAM */
    .bss : {
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > RAM

    /* Stack section */
    .stack : {
        . = ALIGN(8);
        _stack_end = .;
        . = . + 0x400;          /* 1KB stack */
        _stack_start = .;
    } > RAM

    /* Heap section (optional) */
    .heap : {
        _heap_start = .;
        . = . + 0x200;          /* 512B heap */
        _heap_end = .;
    } > RAM

    /* Discard unnecessary sections */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
    }
}

/* Define symbols for startup code */
PROVIDE(_stack_pointer = _stack_start);
PROVIDE(_heap_size = _heap_end - _heap_start);
