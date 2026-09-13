`timescale 1ns/1ps
//note: add explicit connections? or improve naming conventions to be able to use .* for most modules
module rv32i_core #(
    parameter logic [31:0] RESET_PC = 32'h8000_0000
) (
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

    typedef struct packed {
        logic valid;
        logic [31:0] pc;
        logic [31:0] instr;
    } if_id_t;

    typedef struct packed {
        logic valid;

        logic [31:0] pc;

        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [4:0] rd;

        logic [31:0] rs1_data;
        logic [31:0] rs2_data;
        logic [31:0] imm;

        alu_op_t alu_op;
        alu_a_sel_t alu_a_sel;
        alu_b_sel_t alu_b_sel;

        branch_op_t branch_op;
        pc_sel_t pc_sel;

        mem_op_t mem_op;
        wb_sel_t wb_sel;

        logic reg_write;
    } id_ex_t;

    typedef struct packed {
        logic valid;

        logic [31:0] alu_result;
        logic [31:0] store_data;
        logic [31:0] pc_plus_4;
        logic [31:0] imm; //note: could have made alu result hold imm instead when applicable, but to keep the design consistent (for timing comparison later) this will be used for the time being

        logic [4:0] rd;

        mem_op_t mem_op;
        wb_sel_t wb_sel;

        logic reg_write;
    } ex_mem_t;

    typedef struct packed {
        logic valid;

        logic [4:0] rd;
        logic reg_write;

        logic [31:0] wb_value;
    } mem_wb_t;

    if_id_t  if_id_q,  if_id_d;
    id_ex_t  id_ex_q,  id_ex_d;
    ex_mem_t ex_mem_q, ex_mem_d;
    mem_wb_t mem_wb_q, mem_wb_d;

    logic [31:0] pc_q, pc_d;

    always_ff @(posedge clk) begin
        if (reset) begin
            if_id_q <= '0;
            id_ex_q <= '0;
            ex_mem_q <= '0;
            mem_wb_q <= '0;
        end
        else begin
            if_id_q <= if_id_d;
            id_ex_q <= id_ex_d;
            ex_mem_q <= ex_mem_d;
            mem_wb_q <= mem_wb_d;
        end
    end

    always_comb begin
        if_id_d = '0;

        if_id_d.valid = 1'b1;
        if_id_d.pc = pc_q;
        if_id_d.instr = imem_rdata;
    end

    always_comb begin
        id_ex_d = '0;

        id_ex_d.valid = if_id_q.valid && !illegal_instr; //note: turns illegal instructions into bubbles; will likely change for implementation of exceptions/traps eventually
        id_ex_d.pc = if_id_q.pc;

        id_ex_d.rs1 = rs1_addr;
        id_ex_d.rs2 = rs2_addr;
        id_ex_d.rd = rd_addr;

        id_ex_d.rs1_data = rs1_data;
        id_ex_d.rs2_data = rs2_data;

        id_ex_d.imm = imm;

        id_ex_d.alu_op = alu_op;
        id_ex_d.alu_a_sel = alu_a_sel;
        id_ex_d.alu_b_sel = alu_b_sel;

        id_ex_d.branch_op = branch_op;
        id_ex_d.pc_sel = pc_sel;

        id_ex_d.mem_op = mem_op;
        id_ex_d.wb_sel = wb_sel;

        id_ex_d.reg_write = reg_write;
    end

    logic [31:0] fwd_rs1_data, fwd_rs2_data;

    always_comb begin
        fwd_rs1_data = id_ex_q.rs1_data;
        fwd_rs2_data = id_ex_q.rs2_data;
        
        if (ex_mem_q.valid &&
            ex_mem_q.reg_write &&
            (ex_mem_q.rd == id_ex_q.rs1) &&
            (ex_mem_q.rd != 5'b0)
        ) 
        begin
            unique case (ex_mem_q.wb_sel)
                WB_ALU: begin
                    fwd_rs1_data = ex_mem_q.alu_result;
                end
                WB_MEM: begin
                    ; // requires stall; won't work
                    // should be handled in the prior cycle separately
                    //note: could forward load data since it does exist, but combinational path may worsen; test later
                end
                WB_PC4: begin
                    fwd_rs1_data = ex_mem_q.pc_plus_4;
                end
                WB_IMM: begin
                    fwd_rs1_data = ex_mem_q.imm;
                end
            endcase
        end
        else if (mem_wb_q.valid && 
            mem_wb_q.reg_write &&
            (mem_wb_q.rd == id_ex_q.rs1) && 
            (mem_wb_q.rd != 5'b0))
        begin
            fwd_rs1_data = mem_wb_q.wb_value;
        end

        if (ex_mem_q.valid &&
            ex_mem_q.reg_write &&
            (ex_mem_q.rd == id_ex_q.rs2) &&
            (ex_mem_q.rd != 5'b0)
        ) 
        begin
            unique case (ex_mem_q.wb_sel)
                WB_ALU: begin
                    fwd_rs2_data = ex_mem_q.alu_result;
                end
                WB_MEM: begin
                    ;
                end
                WB_PC4: begin
                    fwd_rs2_data = ex_mem_q.pc_plus_4;
                end
                WB_IMM: begin
                    fwd_rs2_data = ex_mem_q.imm;
                end
            endcase
        end
        else if (mem_wb_q.valid && 
            mem_wb_q.reg_write &&
            (mem_wb_q.rd == id_ex_q.rs2) && 
            (mem_wb_q.rd != 5'b0))
        begin
            fwd_rs2_data = mem_wb_q.wb_value;
        end
    end

    always_comb begin
        ex_mem_d = '0;

        ex_mem_d.valid = id_ex_q.valid;

        ex_mem_d.alu_result = alu_result;
        ex_mem_d.store_data = fwd_rs2_data;
        ex_mem_d.pc_plus_4 = id_ex_q.pc + 32'd4;
        ex_mem_d.imm = id_ex_q.imm;

        ex_mem_d.rd = id_ex_q.rd;

        ex_mem_d.mem_op = id_ex_q.mem_op;
        ex_mem_d.wb_sel = id_ex_q.wb_sel;

        ex_mem_d.reg_write = id_ex_q.reg_write;
    end

    always_comb begin
        mem_wb_d = '0;

        mem_wb_d.valid = ex_mem_q.valid;

        mem_wb_d.rd = ex_mem_q.rd;
        mem_wb_d.reg_write = ex_mem_q.reg_write && !mem_misaligned; // still doesn't implement full RV32I behavior

        unique case (ex_mem_q.wb_sel)
            WB_ALU: begin
                mem_wb_d.wb_value = ex_mem_q.alu_result;
            end
            WB_MEM: begin
                mem_wb_d.wb_value = load_data;
            end
            WB_PC4: begin
                mem_wb_d.wb_value = ex_mem_q.pc_plus_4;
            end
            WB_IMM: begin
                mem_wb_d.wb_value = ex_mem_q.imm;
            end
        endcase
    end

    // the values directly below are only for verification purposes
    logic [31:0] id_ex_instr, ex_mem_pc, ex_mem_instr, mem_wb_pc, mem_wb_instr;
    logic [31:0] mem_wb_dmem_addr, mem_wb_dmem_wdata;
    logic [3:0] mem_wb_dmem_wstrb;
    wb_sel_t mem_wb_wb_sel;
    mem_op_t mem_wb_d_mem_op;

    always_ff @(posedge clk) begin
        if (reset) begin
            id_ex_instr <= '0;
            ex_mem_pc <= '0;
            ex_mem_instr <= '0;
            mem_wb_pc <= '0;
            mem_wb_instr <= '0;

            mem_wb_wb_sel <= WB_ALU;
            mem_wb_d_mem_op <= MEM_NONE;
            mem_wb_dmem_addr <= '0;
            mem_wb_dmem_wdata <= '0;
            mem_wb_dmem_wstrb <= '0;
        end

        else begin
            id_ex_instr <= if_id_q.instr;
            ex_mem_pc <= id_ex_q.pc;
            ex_mem_instr <= id_ex_instr;
            mem_wb_pc <= ex_mem_pc;
            mem_wb_instr <= ex_mem_instr;

            mem_wb_wb_sel <= ex_mem_q.wb_sel;
            mem_wb_d_mem_op <= ex_mem_q.mem_op;
            mem_wb_dmem_addr <= dmem_addr;
            mem_wb_dmem_wdata <= dmem_wdata;
            mem_wb_dmem_wstrb <= dmem_wstrb;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            pc_q <= RESET_PC;
        end
        else begin
            pc_q <= pc_d;
        end
    end

    always_comb begin
        imem_addr = pc_q;

        pc_d = pc_q + 32'd4;
        if (id_ex_q.valid) begin
            unique case (id_ex_q.pc_sel)
                    PC_SEQ: ;
                    PC_BRANCH: begin
                        if (branch_taken) begin
                            pc_d = id_ex_q.pc + id_ex_q.imm;
                        end
                    end
                    PC_JAL: begin
                        pc_d = id_ex_q.pc + id_ex_q.imm;
                    end
                    PC_JALR: begin
                        pc_d = (fwd_rs1_data + id_ex_q.imm) & 32'hFFFF_FFFE;
                    end
            endcase
        end
    end

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
        .instruction(if_id_q.instr),

        .alu_op(alu_op),
        .imm_sel(imm_sel),
        .wb_sel(wb_sel),
        .mem_op(mem_op),
        .pc_sel(pc_sel),
        .branch_op(branch_op),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),

        .reg_write(reg_write),
        .illegal_instr(illegal_instr)
    );

    logic [4:0] rs1_addr;
    logic [31:0] rs1_data;
    logic [4:0] rs2_addr;
    logic [31:0] rs2_data;
    logic [4:0] rd_addr;

    assign rs2_addr = if_id_q.instr[24:20];
    assign rs1_addr = if_id_q.instr[19:15];
    assign rd_addr = if_id_q.instr[11:7];

    regfile regfile(
        .clk(clk),

        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),

        .rd_addr(mem_wb_q.rd),
        .rd_data(mem_wb_q.wb_value),

        .rd_write(mem_wb_q.valid && mem_wb_q.reg_write && (mem_wb_q.rd != 5'd0)) // technically not needed (5'd0 check) since we don't actually read from or write to x0 anyways
    );

    logic branch_taken;

    branch_compare branch_compare(
        .rs1_data(fwd_rs1_data),
        .rs2_data(fwd_rs2_data),
        .branch_op(id_ex_q.branch_op),
        .branch_taken(branch_taken)
    );

    logic [31:0] imm;

    imm_gen imm_gen(
        .instr(if_id_q.instr),
        .imm_sel(imm_sel),
        .imm(imm)
    );

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [31:0] alu_result;

    alu alu(
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_op(id_ex_q.alu_op),
        .alu_result(alu_result)
    );

    always_comb begin
        operand_a = '0;
        operand_b = '0;

        if (id_ex_q.alu_a_sel == ALU_A_RS1) begin
            operand_a = fwd_rs1_data;
        end
        else if (id_ex_q.alu_a_sel == ALU_A_PC) begin
            operand_a = id_ex_q.pc;
        end

        if (id_ex_q.alu_b_sel == ALU_B_RS2) begin
            operand_b = fwd_rs2_data;
        end
        else if (id_ex_q.alu_b_sel == ALU_B_IMM) begin
            operand_b = id_ex_q.imm;
        end
    end

    assign dmem_addr = ex_mem_q.alu_result;
    logic mem_misaligned;

    always_comb begin
        mem_misaligned = 1'b0;

        unique case (ex_mem_q.mem_op)
            MEM_LH,
            MEM_LHU,
            MEM_SH: begin
                mem_misaligned = dmem_addr[0];
            end

            MEM_LW,
            MEM_SW: begin
                mem_misaligned = |dmem_addr[1:0];
            end

            default: ;
        endcase
    end

    always_comb begin
        dmem_wdata = '0;
        dmem_wstrb = '0;
        if (ex_mem_q.valid && !mem_misaligned) begin
            unique case (ex_mem_q.mem_op)
                MEM_SB: begin
                    dmem_wdata = {24'b0, ex_mem_q.store_data[7:0]} << (8 * dmem_addr[1:0]);
                    dmem_wstrb = 4'b0001 << dmem_addr[1:0];
                end
                MEM_SH: begin
                    dmem_wdata = {16'b0, ex_mem_q.store_data[15:0]} << (8 * dmem_addr[1:0]);
                    dmem_wstrb = 4'b0011 << dmem_addr[1:0];
                end
                MEM_SW: begin
                    dmem_wdata = ex_mem_q.store_data;
                    dmem_wstrb = 4'b1111;
                end
                default: ;
            endcase
        end
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

        unique case (ex_mem_q.mem_op)
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