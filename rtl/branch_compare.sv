module branch_compare (
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input riscv_pkg::branch_op_t branch_op,
    output logic branch_taken
);

    import riscv_pkg::*;
    
    always_comb begin
        branch_taken = 1'b0;

        unique case (branch_op)
            BR_NONE: ;
            BR_EQ: begin
                branch_taken = (rs1_data == rs2_data);
            end
            BR_NE: begin
                branch_taken = (rs1_data != rs2_data);
            end
            BR_LT: begin
                branch_taken = ($signed(rs1_data) < $signed(rs2_data));
            end
            BR_GE: begin
                branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
            end
            BR_LTU: begin
                branch_taken = (rs1_data < rs2_data);
            end
            BR_GEU: begin
                branch_taken = (rs1_data >= rs2_data);
            end
            default: ;
        endcase
    end

endmodule