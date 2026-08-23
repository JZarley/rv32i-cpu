`timescale 1ns/1ps

module rv32i_system_tb;

    localparam logic [31:0] IMEM_BASE = 32'h8000_0000;

    logic clk;
    logic reset;

    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    logic [31:0] imem [0:255];

    rv32i_system dut (
        .clk(clk),
        .reset(reset),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata)
    );

    always #5 clk = ~clk;

    initial begin
        $readmemh("programs/smoke.hex", imem);
    end

    always_comb begin
        imem_rdata = imem[(imem_addr - IMEM_BASE) >> 2];
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // Execute 3 instructions
        repeat (3) @(posedge clk);

        #1;

        assert (dut.core.regfile.regs[1] == 32'd5)
            else $fatal(1, "x1 incorrect: %h",
                        dut.core.regfile.regs[1]);

        assert (dut.core.regfile.regs[2] == 32'd7)
            else $fatal(1, "x2 incorrect: %h",
                        dut.core.regfile.regs[2]);

        assert (dut.core.regfile.regs[3] == 32'd12)
            else $fatal(1, "x3 incorrect: %h",
                        dut.core.regfile.regs[3]);

        assert (imem_addr == 32'h8000000C)
            else $fatal(1, "PC incorrect: %h", imem_addr);

        assert (dut.core.regfile.regs[0] == 32'd0)
            else $fatal(1, "x0 was modified");

        $display("RV32I smoke test passed.");
        $finish;
    end

endmodule