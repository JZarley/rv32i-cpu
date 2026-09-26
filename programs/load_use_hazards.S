.section .text
.globl _start

_start:
    lui  x1, 0x80000
    addi x1, x1, 0x100

    addi x3, x0, 42
    sw   x3, 0(x1)

    lui  x4, 0x80000
    addi x4, x4, 0x120
    sw   x4, 20(x1)

    lw   x5, 0(x1)
    add  x6, x5, x2

    lw   x5, 0(x1)
    add  x6, x2, x5

    lw   x5, 0(x1)
    addi x6, x2, 5

    lw   x5, 20(x1)
    sw   x7, 0(x5)

    lw   x5, 0(x1)
    sw   x5, 4(x1)

    addi x8, x0, 42

    lw   x5, 0(x1)
    beq  x5, x8, branch_rs1_taken

    addi x9, x0, 99

branch_rs1_taken:
    addi x9, x0, 1

    lw   x5, 0(x1)
    beq  x8, x5, branch_rs2_taken

    addi x10, x0, 99

branch_rs2_taken:
    addi x10, x0, 2
    addi x11, x0, 41

    lw   x5, 0(x1)
    beq  x5, x11, branch_should_not_take

    addi x12, x0, 3
    jal  x0, branch_not_taken_done

branch_should_not_take:
    addi x12, x0, 99

branch_not_taken_done:

done:
    jal x0, done