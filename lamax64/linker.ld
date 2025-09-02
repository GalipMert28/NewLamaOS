/*
 * LAMAX64 Operating System Linker Script
 * Version 1.0.0
 */

ENTRY(disk_main)

SECTIONS
{
    /* Disk loader için 32-bit kod */
    . = 0x8000;
    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}

/* Shell için ayrı section */
ENTRY(shell_main)

SECTIONS
{
    . = 0x9000;
    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}

/* Kernel için 64-bit section */
ENTRY(kernel_main)

SECTIONS
{
    . = 0x100000;
    
    .text : ALIGN(4K) {
        *(.multiboot)
        *(.text)
    }

    .rodata : ALIGN(4K) {
        *(.rodata)
    }

    .data : ALIGN(4K) {
        *(.data)
    }

    .bss : ALIGN(4K) {
        *(COMMON)
        *(.bss)
    }
}

