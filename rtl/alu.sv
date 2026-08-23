`timescale 1ns/1ps

module alu (
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    input riscv_pkg::alu_op_t alu_op,
    output logic [31:0] alu_result
);

    import riscv_pkg::*;

    always_comb begin
        alu_result = '0;

        unique case (alu_op)
            ALU_ADD: begin
                alu_result = operand_a + operand_b;
            end
            ALU_SUB: begin
                alu_result = operand_a - operand_b;
            end
            ALU_AND: begin
                alu_result = operand_a & operand_b;
            end
            ALU_OR: begin
                alu_result = operand_a | operand_b;
            end
            ALU_XOR: begin
                alu_result = operand_a ^ operand_b;
            end
            ALU_SLL: begin
                alu_result = operand_a << operand_b[4:0];
            end
            ALU_SRL: begin
                alu_result = operand_a >> operand_b[4:0];
            end
            ALU_SRA: begin
                alu_result = $signed(operand_a) >>> operand_b[4:0];
            end
            ALU_SLT: begin
                alu_result = {{31{1'b0}}, $signed(operand_a) < $signed(operand_b)};
            end
            ALU_SLTU: begin
                alu_result = {{31{1'b0}}, operand_a < operand_b};
            end
        endcase
    end
endmodule