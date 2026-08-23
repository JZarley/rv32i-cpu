`timescale 1ns/1ps

module rv32i_system (
    input logic clk,
    input logic reset,

    output logic [31:0] imem_addr,
    input logic [31:0] imem_rdata
);

    logic [31:0] dmem_addr;
    logic [3:0] dmem_wstrb;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;

    rv32i_core core (
        .*
    );

    data_memory dmem (
        .*
    );
endmodule