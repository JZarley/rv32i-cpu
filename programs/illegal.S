.section .text
.globl _start

_start:
    addi x1, x0, 5

    # Completely invalid encoding.
    .word 0xffffffff

    # JALR opcode (1100111), but illegal funct3=001.
    # rd=x5, rs1=x0, imm=0.
    .word 0x000012e7

    addi x2, x0, 7

done:
    jal x0, done