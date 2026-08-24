.section .text
.globl _start

_start:
    lui  x1, 0x80000
    addi x1, x1, 0x100

    # Start with a known word: 0x11223344
    lui  x2, 0x11223
    addi x2, x2, 0x344
    sw   x2, 0(x1)

    # Verify byte loads from all four offsets
    lb   x3, 0(x1)      # 0x44
    lb   x4, 1(x1)      # 0x33
    lb   x5, 2(x1)      # 0x22
    lb   x6, 3(x1)      # 0x11

    # Verify SB at offset 0
    addi x7, x0, 0x7f
    sb   x7, 0(x1)
    lbu  x8, 0(x1)      # 0x0000007f

    # Verify SB at offset 1 and LB/LBU sign extension
    addi x7, x0, 0x80
    sb   x7, 1(x1)
    lb   x9, 1(x1)      # 0xffffff80
    lbu  x10, 1(x1)     # 0x00000080

    # Verify SB at offset 2
    addi x7, x0, 0x55
    sb   x7, 2(x1)
    lbu  x11, 2(x1)     # 0x00000055

    # Verify SB at offset 3
    addi x7, x0, 0xaa
    sb   x7, 3(x1)
    lbu  x12, 3(x1)     # 0x000000aa

    # Current word should now be 0xaa55807f
    lw   x13, 0(x1)

    # Verify SH at offset 0
    lui  x14, 0x8
    addi x14, x14, 1    # 0x00008001
    sh   x14, 0(x1)

    lh   x15, 0(x1)     # 0xffff8001
    lhu  x16, 0(x1)     # 0x00008001

    # Verify SH at offset 2
    lui  x17, 0x7
    addi x17, x17, 0x234    # 0x00007234
    sh   x17, 2(x1)

    lh   x18, 2(x1)     # 0x00007234
    lhu  x19, 2(x1)     # 0x00007234

    # Final word should be 0x72348001
    lw   x20, 0(x1)

done:
    jal x0, done