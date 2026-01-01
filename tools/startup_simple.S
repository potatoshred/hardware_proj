/****************************************************************************
 * RISC-V Startup Code for MonoCycleCPU (RV32IM)
 * 简化版本 - 避免全局指针优化
 *
 * This file provides the minimal startup sequence:
 * 1. Initialize stack pointer
 * 2. Clear BSS section
 * 3. Call main()
 * 4. Exit with ECALL
 ****************************************************************************/

.section .text.init
.globl _start

_start:
    # 1. Initialize stack pointer
    la sp, _stack_pointer

    # 2. Clear BSS section
    la a0, _bss_start
    la a1, _bss_end
    bgeu a0, a1, bss_done

bss_clear:
    sw zero, 0(a0)
    addi a0, a0, 4
    bltu a0, a1, bss_clear

bss_done:

    # 3. Call main function
    call main

    # 4. Exit program with ECALL (a7=10 for exit)
_exit:
    li a7, 10               # ECALL exit code
    ecall                   # Trigger exit ECALL
    j _exit                 # Should never reach here

/****************************************************************************
 * Exception/Interrupt handler (optional)
 ****************************************************************************/
.align 4
.globl trap_handler
trap_handler:
    # Save context (if needed)
    # Handle trap
    # Restore context
    mret                    # Return from trap

/****************************************************************************
 * Weak default handlers (can be overridden)
 ****************************************************************************/
.weak trap_handler
