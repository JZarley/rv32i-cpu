.section .text
.globl _start

_start:
    # x1 = loop counter = 10
    addi x1, x0, 10

    # x2 = running sum = 0
    addi x2, x0, 0

loop:
    add  x2, x2, x1
    addi x1, x1, -1
    bne  x1, x0, loop

    # Build data-memory address 0x80000100 in x3
    lui  x3, 0x80000
    addi x3, x3, 0x100

    # Store the sum
    sw   x2, 0(x3)

    # Load it back into a different register
    lw   x4, 0(x3)

    # Use the loaded result in another dependent operation
    addi x5, x4, 1

done:
    jal x0, done