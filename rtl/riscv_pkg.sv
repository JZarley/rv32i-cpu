`timescale 1ns/1ps

package riscv_pkg;

    typedef enum logic [2:0] {
        IMM_I,
        IMM_S,
        IMM_B,
        IMM_U,
        IMM_J
    } imm_sel_t;

    typedef enum logic [3:0] {
        ALU_ADD,
        ALU_SUB,
        ALU_AND,
        ALU_OR,
        ALU_XOR,
        ALU_SLL,
        ALU_SRL,
        ALU_SRA,
        ALU_SLT,
        ALU_SLTU
    } alu_op_t;

    typedef enum logic [1:0] {
        WB_ALU,
        WB_MEM,
        WB_PC4
    } wb_sel_t;

    typedef enum logic [3:0] {
        MEM_NONE,
        MEM_LB,
        MEM_LBU,
        MEM_LH,
        MEM_LHU,
        MEM_LW,
        MEM_SB,
        MEM_SH,
        MEM_SW
    } mem_op_t;
    
    typedef enum logic [1:0] {
        PC_SEQ,
        PC_BRANCH,
        PC_JAL,
        PC_JALR
    } pc_sel_t;

    typedef enum logic [2:0] {
        BR_NONE,
        BR_EQ,
        BR_NE,
        BR_LT,
        BR_GE,
        BR_LTU,
        BR_GEU
    } branch_op_t;

    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_AUIPC  = 7'b0010111;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;

endpackage