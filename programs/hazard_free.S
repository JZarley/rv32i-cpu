.section .text
.globl _start

_start:
    addi x1, x0, 10

    nop
    nop
    nop

    addi x2, x0, 20

    nop
    nop
    nop

    add x3, x1, x2

    nop
    nop
    nop

    lui x4, 0x12345

    nop
    nop
    nop

    sw x3, 0(x0)