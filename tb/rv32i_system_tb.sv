`timescale 1ns/1ps

module rv32i_system_tb;
    import riscv_pkg::*;

    localparam logic [31:0] IMEM_BASE = 32'h8000_0000;

    logic clk;
    logic reset;

    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    logic [31:0] imem [0:255];

    string program_hex;
    int instr_count;

    rv32i_system dut (
        .clk(clk),
        .reset(reset),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata)
    );

    always #5 clk = ~clk;

    initial begin
        if (!$value$plusargs("PROGRAM_HEX=%s", program_hex)) begin
            $fatal(1, "Missing +PROGRAM_HEX=<path>");
        end

        if (!$value$plusargs("INSTR_COUNT=%d", instr_count)) begin
            $fatal(1, "Missing +INSTR_COUNT=<n>");
        end

        $readmemh(program_hex, imem);
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
        repeat (instr_count) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (!reset) begin

            if (dut.core.dmem_wstrb != 4'b0000) begin
                // Store
                $display(
                    "COMMIT pc=%08x instr=%08x mem_addr=%08x mem_wdata=%08x mem_wstrb=%x",
                    dut.core.pc,
                    imem_rdata,
                    dut.core.dmem_addr,
                    dut.core.dmem_wdata,
                    dut.core.dmem_wstrb
                );
            end
            else if (dut.core.wb_sel == WB_MEM &&
                    dut.core.reg_write &&
                    dut.core.rd_addr != 5'd0) begin
                // Load
                $display(
                    "COMMIT pc=%08x instr=%08x rd=%0d rd_data=%08x mem_addr=%08x",
                    dut.core.pc,
                    imem_rdata,
                    dut.core.rd_addr,
                    dut.core.rd_data,
                    dut.core.dmem_addr
                );
            end
            else if (dut.core.reg_write &&
                    dut.core.rd_addr != 5'd0) begin
                // Normal register write
                $display(
                    "COMMIT pc=%08x instr=%08x rd=%0d rd_data=%08x",
                    dut.core.pc,
                    imem_rdata,
                    dut.core.rd_addr,
                    dut.core.rd_data
                );
            end
            else begin
                $display(
                    "COMMIT pc=%08x instr=%08x",
                    dut.core.pc,
                    imem_rdata
                );
            end
        end
    end

endmodule