.section .text
.globl _start

_start:
    lui   x1, 0x12345
    auipc x2, 0x1
    auipc x3, 0x7ffff

done:
    jal x0, done
