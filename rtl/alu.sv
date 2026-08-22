`timescale 1ns/1ps

module alu (
    input logic [31:0] a,
    input logic [31:0] b,
    input riscv_pkg::alu_op_t alu_op,
    output logic [31:0] result
);

    import riscv_pkg::*;

    always_comb begin
        result = '0;

        unique case (alu_op)
            ALU_ADD: begin
                result = a + b;
            end
            ALU_SUB: begin
                result = a - b;
            end
            ALU_AND: begin
                result = a & b;
            end
            ALU_OR: begin
                result = a | b;
            end
            ALU_XOR: begin
                result = a ^ b;
            end
            ALU_SLL: begin
                result = a << b[4:0];
            end
            ALU_SRL: begin
                result = a >> b[4:0];
            end
            ALU_SRA: begin
                result = $signed(a) >>> b[4:0];
            end
            ALU_SLT: begin
                result = {{31{1'b0}}, $signed(a) < $signed(b)};
            end
            ALU_SLTU: begin
                result = {{31{1'b0}}, a < b};
            end
        endcase
    end
endmodule