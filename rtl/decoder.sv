module decoder (
    input logic [31:0] instruction,

    output riscv_pkg::alu_op_t alu_op,
    output riscv_pkg::imm_sel_t imm_sel,
    output riscv_pkg::wb_sel_t wb_sel,
    output riscv_pkg::mem_op_t mem_op,
    output riscv_pkg::pc_sel_t pc_sel,
    output riscv_pkg::branch_op_t branch_op,

    output logic alu_src_imm,
    output logic reg_write,
    output logic illegal_instr
);

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
        illegal_instr = 1'b1;

        unique case (opcode)
            OPCODE_LOAD: begin
                alu_op      = ALU_ADD;
                imm_sel     = IMM_I;
                wb_sel      = WB_MEM;
                pc_sel      = PC_SEQ;
                branch_op   = BR_NONE;
                alu_src_imm = 1'b1;
                reg_write   = 1'b1;
                
                unique case (funct3)
                    3'b000: begin
                        //lb
                        mem_op = MEM_LB;
                        illegal_instr = 1'b0;
                    end
                    3'b001: begin
                        //lh
                        mem_op = MEM_LH;
                        illegal_instr = 1'b0;
                    end
                    3'b010: begin
                        //lw
                        mem_op = MEM_LW;
                        illegal_instr = 1'b0;
                    end
                    3'b100: begin
                        //lbu
                        mem_op = MEM_LBU;
                        illegal_instr = 1'b0;
                    end
                    3'b101: begin
                        //lhu
                        mem_op = MEM_LHU;
                        illegal_instr = 1'b0;
                    end
                    default: ;
                endcase
            end
            OPCODE_OP_IMM: begin
                imm_sel = IMM_I;
                wb_sel = WB_ALU;
                mem_op = MEM_NONE;
                pc_sel = PC_SEQ;
                branch_op = BR_NONE;
                alu_src_imm = 1'b1;
                reg_write = 1'b1;

                unique case (funct3)
                    3'b000:  begin
                        alu_op = ALU_ADD;
                        illegal_instr = 1'b0;
                        //addi
                    end
                    3'b001: begin
                        //slli only
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_SLL;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b010: begin
                        //slti only
                        alu_op = ALU_SLT;
                        illegal_instr = 1'b0;
                    end
                    3'b011: begin
                        //sltiu only
                        alu_op = ALU_SLTU;
                        illegal_instr = 1'b0;
                    end
                    3'b100: begin
                        //xori only
                        alu_op = ALU_XOR;
                        illegal_instr = 1'b0;
                    end
                    3'b101: begin
                        //srli, srai, all zeroes, 01'0
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_SRL;
                                illegal_instr = 1'b0;
                            end
                            7'b0100000: begin
                                alu_op = ALU_SRA;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b110: begin
                        //ori only
                        alu_op = ALU_OR;
                        illegal_instr = 1'b0;
                    end
                    3'b111: begin
                        //andi only
                        alu_op = ALU_AND;
                        illegal_instr = 1'b0;
                    end
                    default: ;
                endcase
            end
            OPCODE_AUIPC: begin
                
            end
            OPCODE_STORE: begin
                
            end
            OPCODE_OP: begin
                imm_sel = IMM_I;
                wb_sel = WB_ALU;
                mem_op = MEM_NONE;
                pc_sel = PC_SEQ;
                branch_op = BR_NONE;
                alu_src_imm = 1'b0;
                reg_write = 1'b1;

                unique case (funct3)
                    3'b000: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_ADD;
                                illegal_instr = 1'b0;
                            end
                            7'b0100000: begin
                                alu_op = ALU_SUB;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b001: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_SLL;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b010: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_SLT;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b011: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_SLTU;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b100: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_XOR;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b101: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_SRL;
                                illegal_instr = 1'b0;
                            end
                            7'b0100000: begin
                                alu_op = ALU_SRA;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b110: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_OR;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    3'b111: begin
                        unique case (funct7)
                            7'b0000000: begin
                                alu_op = ALU_AND;
                                illegal_instr = 1'b0;
                            end
                            default: ;
                        endcase
                    end
                    default: ;
                endcase
            end
            OPCODE_LUI: begin
                
            end
            OPCODE_BRANCH: begin
                
            end
            OPCODE_JALR: begin
                
            end
            OPCODE_JAL: begin
                
            end
            default: ;
        endcase

        reg_write = reg_write && !illegal_instr;
    end
endmodule