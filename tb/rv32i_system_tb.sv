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

    int commit_count = 0;
    int cycle_count = 0;

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
    end

    always @(posedge clk) begin
        if (!reset) begin
            cycle_count++;

            if (dut.core.mem_wb_q.valid)
                commit_count++;

            if (commit_count == instr_count)
                $finish;

            if (cycle_count > 1234)
                $fatal(1, "Simulation timeout");
        end
    end
    
    always @(posedge clk) begin
        if (!reset) begin
            if (dut.core.id_ex_q.rs1 == 5'd0) begin
                assert (dut.core.id_ex_q.rs1_data == 32'd0)
                    else $fatal(1, "x0 returned nonzero data on rs1 port");
            end

            if (dut.core.id_ex_q.rs2 == 5'd0) begin
                assert (dut.core.id_ex_q.rs2_data == 32'd0)
                    else $fatal(1, "x0 returned nonzero data on rs2 port");
            end

            if (dut.core.mem_wb_q.valid) begin
                if (dut.core.mem_wb_instr[6:0] == 7'b0100011) begin
                    // Store
                    $display(
                        "COMMIT pc=%08x instr=%08x mem_addr=%08x mem_wdata=%08x",
                        dut.core.mem_wb_pc,
                        dut.core.mem_wb_instr,
                        dut.core.mem_wb_dmem_addr,
                        dut.core.mem_wb_store_data
                    );
                end
                else if (dut.core.mem_wb_instr[6:0] == 7'b0000011 &&
                        dut.core.mem_wb_q.reg_write &&
                        dut.core.mem_wb_q.rd != 5'd0) begin
                    // Load
                    $display(
                        "COMMIT pc=%08x instr=%08x rd=%0d rd_data=%08x mem_addr=%08x",
                        dut.core.mem_wb_pc,
                        dut.core.mem_wb_instr,
                        dut.core.mem_wb_q.rd,
                        dut.core.mem_wb_q.wb_value,
                        dut.core.mem_wb_dmem_addr
                    );
                end
                else if (dut.core.mem_wb_q.reg_write &&
                        dut.core.mem_wb_q.rd != 5'd0) begin
                    // Normal register write
                    $display(
                        "COMMIT pc=%08x instr=%08x rd=%0d rd_data=%08x",
                        dut.core.mem_wb_pc,
                        dut.core.mem_wb_instr,
                        dut.core.mem_wb_q.rd,
                        dut.core.mem_wb_q.wb_value
                    );
                end
                else begin
                    $display(
                        "COMMIT pc=%08x instr=%08x",
                        dut.core.mem_wb_pc,
                        dut.core.mem_wb_instr
                    );
                end
            end
        end
    end
endmodule