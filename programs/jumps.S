.section .text
.globl _start

_start:
    # JAL must jump over this instruction and write PC+4 to x1.
    jal  x1, after_jal
    addi x10, x0, 1

after_jal:
    # x2 = address associated with this AUIPC
    auipc x2, 0

    # target is 16 bytes ahead of the AUIPC.
    # Make the address intentionally odd to test JALR's bit-0 clearing.
    addi x2, x2, 17

    jalr x3, 0(x2)

    # Must be skipped.
    addi x11, x0, 2

target:
    addi x4, x0, 42

done:
    jal x0, done
