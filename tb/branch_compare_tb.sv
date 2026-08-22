`timescale 1ns/1ps

module branch_compare_tb;

    import riscv_pkg::*;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    branch_op_t  branch_op;
    logic        branch_taken;

    branch_compare dut (
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .branch_op    (branch_op),
        .branch_taken (branch_taken)
    );


    task automatic check_branch(
        input branch_op_t op,
        input logic [31:0] rs1,
        input logic [31:0] rs2,
        input logic        expected,
        input string       test_name
    );
        begin
            branch_op = op;
            rs1_data  = rs1;
            rs2_data  = rs2;
            #1;

            assert (branch_taken == expected)
                else $fatal(
                    1,
                    "%s failed: rs1=%h rs2=%h expected=%b actual=%b",
                    test_name,
                    rs1,
                    rs2,
                    expected,
                    branch_taken
                );
        end
    endtask


    initial begin
        rs1_data     = '0;
        rs2_data     = '0;
        branch_op    = BR_NONE;


        //--------------------------------------------------
        // BR_NONE
        check_branch(
            BR_NONE,
            32'd10,
            32'd10,
            1'b0,
            "BR_NONE"
        );


        //--------------------------------------------------
        // Equality
        check_branch(
            BR_EQ,
            32'd25,
            32'd25,
            1'b1,
            "BEQ true"
        );

        check_branch(
            BR_EQ,
            32'd25,
            32'd26,
            1'b0,
            "BEQ false"
        );


        //--------------------------------------------------
        // Inequality
        check_branch(
            BR_NE,
            32'd25,
            32'd26,
            1'b1,
            "BNE true"
        );

        check_branch(
            BR_NE,
            32'd25,
            32'd25,
            1'b0,
            "BNE false"
        );


        //--------------------------------------------------
        // Signed less-than
        check_branch(
            BR_LT,
            32'd5,
            32'd10,
            1'b1,
            "BLT positive true"
        );

        check_branch(
            BR_LT,
            32'd10,
            32'd5,
            1'b0,
            "BLT positive false"
        );

        // -1 < +1
        check_branch(
            BR_LT,
            32'hFFFF_FFFF,
            32'h0000_0001,
            1'b1,
            "BLT signed negative"
        );

        // Largest positive is not less than most-negative signed value
        check_branch(
            BR_LT,
            32'h7FFF_FFFF,
            32'h8000_0000,
            1'b0,
            "BLT signed extremes"
        );


        //--------------------------------------------------
        // Signed greater-than-or-equal
        check_branch(
            BR_GE,
            32'd10,
            32'd5,
            1'b1,
            "BGE positive true"
        );

        check_branch(
            BR_GE,
            32'd5,
            32'd10,
            1'b0,
            "BGE positive false"
        );

        check_branch(
            BR_GE,
            32'hFFFF_FFFF,   // -1
            32'h0000_0001,   // +1
            1'b0,
            "BGE signed negative"
        );

        // Equality must satisfy >=
        check_branch(
            BR_GE,
            32'h8000_0000,
            32'h8000_0000,
            1'b1,
            "BGE equality"
        );


        //--------------------------------------------------
        // Unsigned less-than
        check_branch(
            BR_LTU,
            32'd5,
            32'd10,
            1'b1,
            "BLTU basic true"
        );

        // 0xFFFFFFFF is huge when unsigned
        check_branch(
            BR_LTU,
            32'hFFFF_FFFF,
            32'h0000_0001,
            1'b0,
            "BLTU signedness distinction"
        );


        //--------------------------------------------------
        // Unsigned greater-than-or-equal
        check_branch(
            BR_GEU,
            32'hFFFF_FFFF,
            32'h0000_0001,
            1'b1,
            "BGEU signedness distinction"
        );

        check_branch(
            BR_GEU,
            32'd5,
            32'd10,
            1'b0,
            "BGEU basic false"
        );

        check_branch(
            BR_GEU,
            32'd10,
            32'd10,
            1'b1,
            "BGEU equality"
        );


        //--------------------------------------------------
        $display("All branch comparator tests passed");
        $finish;
    end

endmodule