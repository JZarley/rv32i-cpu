module imm_gen(
    input logic [31:0] instr,
    input riscv_pkg::imm_sel_t imm_sel,
    output logic [31:0] imm
);

    import riscv_pkg::*;

    always_comb begin
        imm = '0;

        unique case (imm_sel)
            IMM_I: begin
                imm = {{21{instr[31]}}, instr[30:20]};
            end
            IMM_S: begin
                imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
            end
            IMM_B: begin
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            IMM_U: begin
                imm = {instr[31:12], {12{1'b0}}};
            end
            IMM_J: begin
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0};
            end
        endcase
    end
endmodule