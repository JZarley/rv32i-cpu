.section .text
.globl _start

_start:
    lui  x1, 0x80000
    addi x1, x1, 0x100

    # array = {7, 3, 9, 1, 5, 2, 8, 4}
    addi x2, x0, 7
    sw   x2, 0(x1)

    addi x2, x0, 3
    sw   x2, 4(x1)

    addi x2, x0, 9
    sw   x2, 8(x1)

    addi x2, x0, 1
    sw   x2, 12(x1)

    addi x2, x0, 5
    sw   x2, 16(x1)

    addi x2, x0, 2
    sw   x2, 20(x1)

    addi x2, x0, 8
    sw   x2, 24(x1)

    addi x2, x0, 4
    sw   x2, 28(x1)

    addi x3, x0, 1          # i = 1
    addi x4, x0, 8          # n = 8

outer_loop:
    bge  x3, x4, done

    slli x5, x3, 2
    add  x5, x1, x5
    lw   x6, 0(x5)          # key = array[i]

    addi x7, x3, -1         # j = i - 1

inner_loop:
    blt  x7, x0, insert_key

    slli x8, x7, 2
    add  x8, x1, x8
    lw   x9, 0(x8)          # array[j]

    bge  x6, x9, insert_key

    sw   x9, 4(x8)          # array[j+1] = array[j]
    addi x7, x7, -1
    jal  x0, inner_loop

insert_key:
    addi x7, x7, 1
    slli x8, x7, 2
    add  x8, x1, x8
    sw   x6, 0(x8)

    addi x3, x3, 1
    jal  x0, outer_loop

done:
    jal  x0, done