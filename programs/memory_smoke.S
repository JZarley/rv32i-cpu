.section .text
.globl _start

_start:
    lui  x4, 0x80000
    addi x4, x4, 0x100

    addi x5, x0, 42
    sw   x5, 0(x4)
    lw   x6, 0(x4)

done:
    jal x0, done
