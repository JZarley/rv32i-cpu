.section .text
.globl _start

_start:
    addi x1, x0, 10
    addi x2, x0, 3

    add  x3,  x1, x2
    sub  x4,  x1, x2
    sll  x5,  x1, x2
    slt  x6,  x2, x1
    sltu x7,  x2, x1
    xor  x8,  x1, x2
    srl  x9,  x1, x2
    or   x10, x1, x2
    and  x11, x1, x2

    addi x12, x0, -16
    addi x13, x0, 2
    sra  x14, x12, x13

done:
    jal x0, done
