.section .text
.globl _start

_start:
    addi x1, x0, 5
    addi x2, x0, 5
    addi x3, x0, 7
    addi x4, x0, -1

    # BEQ taken
    beq  x1, x2, beq_taken
    addi x10, x0, 1
beq_taken:

    # BEQ not taken
    beq  x1, x3, beq_not_taken_target
    addi x11, x0, 2
beq_not_taken_target:

    # BNE taken
    bne  x1, x3, bne_taken
    addi x12, x0, 3
bne_taken:

    # BNE not taken
    bne  x1, x2, bne_not_taken_target
    addi x13, x0, 4
bne_not_taken_target:

    # BLT signed: -1 < 5, taken
    blt  x4, x1, blt_taken
    addi x14, x0, 5
blt_taken:

    # BLT not taken: 7 < 5 is false
    blt  x3, x1, blt_not_taken_target
    addi x15, x0, 6
blt_not_taken_target:

    # BGE signed: 7 >= 5, taken
    bge  x3, x1, bge_taken
    addi x16, x0, 7
bge_taken:

    # BGE not taken: -1 >= 5 is false
    bge  x4, x1, bge_not_taken_target
    addi x17, x0, 8
bge_not_taken_target:

    # BLTU unsigned: 5 < 7, taken
    bltu x1, x3, bltu_taken
    addi x18, x0, 9
bltu_taken:

    # BLTU unsigned: 0xffffffff < 5 is false
    bltu x4, x1, bltu_not_taken_target
    addi x19, x0, 10
bltu_not_taken_target:

    # BGEU unsigned: 0xffffffff >= 5, taken
    bgeu x4, x1, bgeu_taken
    addi x20, x0, 11
bgeu_taken:

    # BGEU unsigned: 5 >= 7 is false
    bgeu x1, x3, bgeu_not_taken_target
    addi x21, x0, 12
bgeu_not_taken_target:

done:
    jal x0, done
