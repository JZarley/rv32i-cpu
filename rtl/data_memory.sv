`timescale 1ns/1ps

module data_memory #(
    parameter logic [31:0] BASE_ADDR = 32'h8000_0000,
    parameter int MEM_BYTES = 1024
) (
    input logic clk,
    input logic [31:0] dmem_addr,
    input logic [31:0] dmem_wdata,
    input logic [3:0] dmem_wstrb,
    output logic [31:0] dmem_rdata
);

    logic [7:0] mem [0:MEM_BYTES-1];
    logic [31:0] aligned_addr;
    logic [31:0] mem_offset;

    assign aligned_addr = {dmem_addr[31:2], 2'b00};
    assign mem_offset = aligned_addr - BASE_ADDR;

    always_comb begin
        dmem_rdata = {
            mem[mem_offset + 32'd3],
            mem[mem_offset + 32'd2],
            mem[mem_offset + 32'd1],
            mem[mem_offset]
        };
    end

    always_ff @(posedge clk) begin
        if (dmem_wstrb[0]) begin
            mem[mem_offset] <= dmem_wdata[7:0];
        end

        if (dmem_wstrb[1]) begin
            mem[mem_offset + 32'd1] <= dmem_wdata[15:8];
        end

        if (dmem_wstrb[2]) begin
            mem[mem_offset + 32'd2] <= dmem_wdata[23:16];
        end

        if (dmem_wstrb[3]) begin
            mem[mem_offset + 32'd3] <= dmem_wdata[31:24];
        end
    end
endmodule