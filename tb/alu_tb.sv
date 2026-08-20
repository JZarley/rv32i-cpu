`timescale 1ns/1ps

module alu_tb;

    import riscv_pkg::*;

    logic [31:0] a;
    logic [31:0] b;
    alu_op_t     alu_op;
    logic [31:0] result;

    alu dut (
        .a      (a),
        .b      (b),
        .alu_op (alu_op),
        .result (result)
    );

    task automatic check_result(
        input alu_op_t     op,
        input logic [31:0] operand_a,
        input logic [31:0] operand_b,
        input logic [31:0] expected,
        input string       test_name
    );
        begin
            a      = operand_a;
            b      = operand_b;
            alu_op = op;
            #1;

            assert (result == expected)
                else $fatal(
                    1,
                    "%s failed: a=%h b=%h expected=%h actual=%h",
                    test_name,
                    operand_a,
                    operand_b,
                    expected,
                    result
                );
        end
    endtask

    initial begin
        a      = '0;
        b      = '0;
        alu_op = ALU_ADD;

        //--------------------------------------------------
        // ADD
        check_result(
            ALU_ADD,
            32'd10,
            32'd25,
            32'd35,
            "ADD basic"
        );

        check_result(
            ALU_ADD,
            32'hFFFF_FFFF,
            32'd1,
            32'h0000_0000,
            "ADD wraparound"
        );

        //--------------------------------------------------
        // SUB
        check_result(
            ALU_SUB,
            32'd25,
            32'd10,
            32'd15,
            "SUB basic"
        );

        check_result(
            ALU_SUB,
            32'd0,
            32'd1,
            32'hFFFF_FFFF,
            "SUB wraparound"
        );

        //--------------------------------------------------
        // AND
        check_result(
            ALU_AND,
            32'hF0F0_AA55,
            32'h0FF0_0F0F,
            32'h00F0_0A05,
            "AND"
        );

        //--------------------------------------------------
        // OR
        check_result(
            ALU_OR,
            32'hF000_00F0,
            32'h0F00_0F00,
            32'hFF00_0FF0,
            "OR"
        );

        //--------------------------------------------------
        // XOR
        check_result(
            ALU_XOR,
            32'hFFFF_0000,
            32'h0F0F_0F0F,
            32'hF0F0_0F0F,
            "XOR"
        );

        //--------------------------------------------------
        // SLL
        check_result(
            ALU_SLL,
            32'h0000_0001,
            32'd4,
            32'h0000_0010,
            "SLL basic"
        );

        check_result(
            ALU_SLL,
            32'h0000_0001,
            32'd31,
            32'h8000_0000,
            "SLL maximum shift"
        );

        // Only b[4:0] is used.
        // 35 decimal -> low 5 bits = 3.
        check_result(
            ALU_SLL,
            32'h0000_0001,
            32'd35,
            32'h0000_0008,
            "SLL masks shift amount"
        );

        //--------------------------------------------------
        // SRL
        check_result(
            ALU_SRL,
            32'h8000_0000,
            32'd1,
            32'h4000_0000,
            "SRL zero fill"
        );

        check_result(
            ALU_SRL,
            32'hFFFF_FFFF,
            32'd4,
            32'h0FFF_FFFF,
            "SRL logical shift"
        );

        //--------------------------------------------------
        // SRA
        check_result(
            ALU_SRA,
            32'h8000_0000,
            32'd1,
            32'hC000_0000,
            "SRA sign extension"
        );

        check_result(
            ALU_SRA,
            32'hFFFF_FFF8,
            32'd1,
            32'hFFFF_FFFC,
            "SRA negative eight"
        );

        check_result(
            ALU_SRA,
            32'h4000_0000,
            32'd1,
            32'h2000_0000,
            "SRA positive value"
        );

        //--------------------------------------------------
        // SLT - signed comparison
        check_result(
            ALU_SLT,
            32'hFFFF_FFFF, // -1
            32'h0000_0001, // +1
            32'd1,
            "SLT signed true"
        );

        check_result(
            ALU_SLT,
            32'h0000_0001,
            32'hFFFF_FFFF, // -1
            32'd0,
            "SLT signed false"
        );

        check_result(
            ALU_SLT,
            32'h8000_0000, // most negative signed 32-bit value
            32'h7FFF_FFFF, // largest positive signed 32-bit value
            32'd1,
            "SLT signed extremes"
        );

        //--------------------------------------------------
        // SLTU - unsigned comparison
        check_result(
            ALU_SLTU,
            32'hFFFF_FFFF,
            32'h0000_0001,
            32'd0,
            "SLTU unsigned false"
        );

        check_result(
            ALU_SLTU,
            32'h0000_0001,
            32'hFFFF_FFFF,
            32'd1,
            "SLTU unsigned true"
        );

        //--------------------------------------------------
        // Equality cases
        check_result(
            ALU_SLT,
            32'h1234_5678,
            32'h1234_5678,
            32'd0,
            "SLT equality"
        );

        check_result(
            ALU_SLTU,
            32'h1234_5678,
            32'h1234_5678,
            32'd0,
            "SLTU equality"
        );

        $display("All ALU tests passed");
        $finish;
    end

endmodule