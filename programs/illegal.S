.section .text
.globl _start

_start:
    addi x1, x0, 5

    .word 0xffffffff

    addi x2, x0, 7

done:
    jal x0, done