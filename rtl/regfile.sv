module regfile (
    input logic clk,

    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,

    input logic [4:0] rd_addr,
    input logic [31:0] rd_data,
    input logic rd_write
);

    logic [31:0] regs [0:31];

    always_ff @(posedge clk) begin
        if (rd_write && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;
        end
    end

    always_comb begin
        rs1_data = (rs1_addr == 5'd0) ? 0 : regs[rs1_addr];
        rs2_data = (rs2_addr == 5'd0) ? 0 : regs[rs2_addr];
    end
endmodule