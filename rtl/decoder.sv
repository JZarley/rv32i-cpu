module decoder (
    input logic [31:0] instruction,

    output riscv_pkg::alu_op_t alu_op,
    output riscv_pkg::imm_sel_t imm_sel,
    output riscv_pkg::wb_sel_t wb_sel,
    output riscv_pkg::mem_op_t mem_op,
    output riscv_pkg::pc_sel_t pc_sel,
    output riscv_pkg::branch_op_t branch_op,

    output logic alu_src_imm,
    output logic reg_write
)

    import riscv_pkg::*;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    always_comb begin
        opcode = instruction[6:0];
        funct3 = instruction[14:12];
        funct7 = instruction[31:25];

        alu_op      = ALU_ADD;
        imm_sel     = IMM_I;
        wb_sel      = WB_ALU;
        mem_op      = MEM_NONE;
        pc_sel      = PC_SEQ;
        branch_op   = BR_NONE;
        alu_src_imm = 1'b0;
        reg_write   = 1'b0;

        unique case (opcode)
            OPCODE_LOAD: begin
                a
            end
            OPCODE_OP_IMM: begin
                a
            end
            OPCODE_AUIPC: begin
                a
            end
            OPCODE_STORE: begin
                a
            end
            OPCODE_OP: begin
                alu_src_imm = 0;
                reg_write = 1;
                wb_sel = WB_ALU;
                mem_op = MEM_NONE;

                unique case (funct3)
                    3'b000: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_ADD;
                            end
                            7'b0100000: begin
                                alu_op = ALU_SUB;
                            end
                        endcase
                    end
                    3'b001: begin
                        alu_op = ALU_SLL;
                    end
                    3'b010: begin
                        alu_op = ALU_SLT;
                    end
                    3'b011: begin
                        alu_op = ALU_SLTU;
                    end
                    3'b100: begin
                        alu_op = ALU_XOR;
                    end
                    3'b101: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_SRL;
                            end
                            7'b0100000: begin
                                alu_op = ALU_SRA;
                            end
                        endcase
                    end
                    3'b110: begin
                        alu_op = ALU_OR;
                    end
                    3'b111: begin
                        alu_op = ALU_AND;
                    end
                endcase
            end
            OPCODE_LUI: begin
                a
            end
            OPCODE_BRANCH: begin
                a
            end
            OPCODE_JALR: begin
                a
            end
            OPCODE_JAL: begin
                a
            end
        endcase
    end
endmodule