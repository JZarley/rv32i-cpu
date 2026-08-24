.section .text
.globl _start

_start:
    lui  x1, 0x80000
    addi x1, x1, 0x100

    addi x2, x0, 0x55

    # Misaligned store
    sh   x2, 1(x1)

    # Misaligned load
    lh   x3, 1(x1)

done:
    jal x0, done