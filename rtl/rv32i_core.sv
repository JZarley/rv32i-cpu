`timescale 1ns/1ps
//note: add explicit connections? or improve naming conventions to be able to use .* for most modules
module rv32i_core (
    input logic clk,
    input logic reset,

    output logic [31:0] imem_addr,
    input logic [31:0] imem_rdata,
    
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0] dmem_wstrb,
    input logic [31:0] dmem_rdata
);

    import riscv_pkg::*;

    logic [31:0] pc;
    logic [31:0] next_pc;

    riscv_pkg::alu_op_t alu_op;
    riscv_pkg::imm_sel_t imm_sel;
    riscv_pkg::wb_sel_t wb_sel;
    riscv_pkg::mem_op_t mem_op;
    riscv_pkg::pc_sel_t pc_sel;
    riscv_pkg::branch_op_t branch_op;
    riscv_pkg::alu_a_sel_t alu_a_sel;
    riscv_pkg::alu_b_sel_t alu_b_sel;
    logic reg_write;
    logic illegal_instr;

    decoder decoder(
        .instruction(imem_rdata),
        .*
    );

    logic [4:0] rs1_addr;
    logic [31:0] rs1_data;
    logic [4:0] rs2_addr;
    logic [31:0] rs2_data;
    logic [4:0] rd_addr;
    logic [31:0] rd_data;

    assign rs2_addr = imem_rdata[24:20];
    assign rs1_addr = imem_rdata[19:15];
    assign rd_addr = imem_rdata[11:7];

    regfile regfile(
        .*,
        .rd_write(reg_write) // note: need writeback to be safe?
    );

    logic branch_taken;

    branch_compare branch_compare(
        .*
    );

    always_comb begin
        rd_data = '0;

        unique case (wb_sel)
            WB_ALU: begin
                rd_data = alu_result;
            end
            WB_MEM: begin
                rd_data = load_data;
            end
            WB_PC4: begin
                rd_data = pc + 32'd4;
            end
            WB_IMM: begin
                rd_data = imm;
            end
            default: ;
        endcase
    end

    logic [31:0] imm;

    imm_gen imm_gen(
        .instr(imem_rdata),
        .*
    );

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [31:0] alu_result;

    alu alu(
        .*
    );

    always_comb begin
        operand_a = '0;
        operand_b = '0;

        if (alu_a_sel == ALU_A_RS1) begin
            operand_a = rs1_data;
        end
        else if (alu_a_sel == ALU_A_PC) begin
            operand_a = pc;
        end

        if (alu_b_sel == ALU_B_RS2) begin
            operand_b = rs2_data;
        end
        else if (alu_b_sel == ALU_B_IMM) begin
            operand_b = imm;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= '0;
        end
        else begin
            pc <= next_pc;
        end
    end

    always_comb begin
        imem_addr = pc;

        next_pc = pc + 4;
        unique case (pc_sel)
                PC_SEQ: ;
                PC_BRANCH: begin
                    if (branch_taken) begin
                        next_pc = pc + imm;
                    end
                end
                PC_JAL: begin
                    next_pc = pc + imm;
                end
                PC_JALR: begin
                    next_pc = (rs1_data + imm) & 32'hFFFF_FFFE;
                end
        endcase
    end

    assign dmem_addr = alu_result;

    always_comb begin
        dmem_wdata = '0;
        dmem_wstrb = '0;

        unique case (mem_op)
            MEM_SB: begin
                dmem_wdata = {24'b0, rs2_data[7:0]} << (8 * dmem_addr[1:0]);
                dmem_wstrb = 4'b0001 << dmem_addr[1:0];
            end
            MEM_SH: begin
                dmem_wdata = {16'b0, rs2_data[15:0]} << (8 * dmem_addr[1:0]);
                dmem_wstrb = 4'b0011 << dmem_addr[1:0];
            end
            MEM_SW: begin
                dmem_wdata = rs2_data;
                dmem_wstrb = 4'b1111;
            end
            default: ;
        endcase
    end

    logic [7:0] load_byte;
    logic [15:0] load_half;
    logic [31:0] load_data;

    always_comb begin
        unique case (dmem_addr[1:0])
            2'b00: load_byte = dmem_rdata[7:0];
            2'b01: load_byte = dmem_rdata[15:8];
            2'b10: load_byte = dmem_rdata[23:16];
            2'b11: load_byte = dmem_rdata[31:24];
        endcase
    end

    always_comb begin
        unique case (dmem_addr[1])
            1'b0: load_half = dmem_rdata[15:0];
            1'b1: load_half = dmem_rdata[31:16];
        endcase
    end

    always_comb begin
        load_data = '0;

        unique case (mem_op)
            MEM_LB: begin
                load_data = {{24{load_byte[7]}}, load_byte};
            end
            MEM_LBU: begin
                load_data = {24'b0, load_byte};
            end
            MEM_LH: begin
                load_data = {{16{load_half[15]}}, load_half};
            end
            MEM_LHU: begin
                load_data = {16'b0, load_half};
            end
            MEM_LW: begin
                load_data = dmem_rdata;
            end
            default: ;
        endcase
    end
endmodule