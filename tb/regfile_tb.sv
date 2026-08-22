`timescale 1ns/1ps

module regfile_tb;

    logic clk;

    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    logic [4:0] rd_addr;
    logic [31:0] rd_data;
    logic rd_write;

    regfile dut (
        .clk       (clk),

        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data),

        .rd_addr (rd_addr),
        .rd_data (rd_data),
        .rd_write (rd_write)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic write_reg(
        input logic [4:0] addr,
        input logic [31:0] data
    );
        begin
            rd_addr = addr;
            rd_data = data;
            rd_write = 1'b1;

            @(posedge clk);
            #1;

            rd_write = 1'b0;
        end
    endtask

    task automatic check_reads(
        input logic [4:0] addr1,
        input logic [31:0] expected1,
        input logic [4:0] addr2,
        input logic [31:0] expected2,
        input string test_name
    );
        begin
            rs1_addr = addr1;
            rs2_addr = addr2;
            #1;

            assert (rs1_data == expected1)
                else $fatal(
                    1,
                    "%s: rs1 mismatch: addr=%0d expected=%h actual=%h",
                    test_name,
                    addr1,
                    expected1,
                    rs1_data
                );

            assert (rs2_data == expected2)
                else $fatal(
                    1,
                    "%s: rs2 mismatch: addr=%0d expected=%h actual=%h",
                    test_name,
                    addr2,
                    expected2,
                    rs2_data
                );
        end
    endtask

    initial begin
        rs1_addr = '0;
        rs2_addr = '0;

        rd_addr  = '0;
        rd_data  = '0;
        rd_write = 1'b0;

        check_reads(
            5'd0,
            32'd0,
            5'd0,
            32'd0,
            "x0 reads zero"
        );

        write_reg(
            5'd5,
            32'hAAAA_5555
        );

        write_reg(
            5'd9,
            32'h1234_5678
        );

        check_reads(
            5'd5,
            32'hAAAA_5555,
            5'd9,
            32'h1234_5678,
            "dual register read"
        );

        check_reads(
            5'd9,
            32'h1234_5678,
            5'd5,
            32'hAAAA_5555,
            "swapped read ports"
        );

        check_reads(
            5'd5,
            32'hAAAA_5555,
            5'd5,
            32'hAAAA_5555,
            "same register on both ports"
        );

        rd_addr  = 5'd5;
        rd_data  = 32'hDEAD_BEEF;
        rd_write = 1'b0;

        @(posedge clk);
        #1;

        check_reads(
            5'd5,
            32'hAAAA_5555,
            5'd9,
            32'h1234_5678,
            "disabled write"
        );

        write_reg(
            5'd5,
            32'hDEAD_BEEF
        );

        check_reads(
            5'd5,
            32'hDEAD_BEEF,
            5'd9,
            32'h1234_5678,
            "register overwrite"
        );

        write_reg(
            5'd0,
            32'hFFFF_FFFF
        );

        check_reads(
            5'd0,
            32'd0,
            5'd5,
            32'hDEAD_BEEF,
            "x0 always '0"
        );

        rd_addr  = 5'd0;
        rd_write = 1'b0;

        $display("PASS: regfile");
        $finish;
    end

endmodule