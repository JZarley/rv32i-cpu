.section .text
.globl _start

_start:
    addi x1, x0, 5
    addi x2, x0, 7

    # EX/MEM -> rs1
    add  x3, x2, x1        # x3 = 12

    # MEM/WB -> rs1
    addi x4, x0, 3
    nop
    add  x5, x4, x1        # x5 = 8

    # dual-source forwarding
    addi x6, x0, 10
    addi x7, x0, 20
    add  x8, x6, x7        # x8 = 30

    # newest producer must win
    addi x9, x0, 1
    addi x9, x9, 1
    add  x10, x9, x0       # x10 = 2

    # store-data forwarding
    addi x11, x0, 42
    sw   x11, 0(x0)
    