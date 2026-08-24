.section .text
.globl _start

_start:
    addi  x1,  x0, 10
    addi  x2,  x0, -1

    slti  x3,  x2, 1
    sltiu x4,  x2, 1

    xori  x5,  x1, 0xF
    ori   x6,  x1, 0x5
    andi  x7,  x1, 0x6

    slli  x8,  x1, 3
    srli  x9,  x8, 2

    addi  x10, x0, -16
    srai  x11, x10, 2

done:
    jal x0, done
