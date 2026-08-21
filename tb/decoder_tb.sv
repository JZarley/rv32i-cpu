`timescale 1ns/1ps

module decoder_tb;

    import riscv_pkg::*;

    //--------------------------------------------------
    // DUT signals
    logic [31:0] instruction;

    alu_op_t     alu_op;
    imm_sel_t    imm_sel;
    wb_sel_t     wb_sel;
    mem_op_t     mem_op;
    pc_sel_t     pc_sel;
    branch_op_t  branch_op;
    alu_a_sel_t  alu_a_sel;
    alu_b_sel_t  alu_b_sel;

    logic        reg_write;
    logic        illegal_instr;


    //--------------------------------------------------
    // DUT
    decoder dut (
        .instruction   (instruction),

        .alu_op        (alu_op),
        .imm_sel       (imm_sel),
        .wb_sel        (wb_sel),
        .mem_op        (mem_op),
        .pc_sel        (pc_sel),
        .branch_op     (branch_op),
        .alu_a_sel     (alu_a_sel),
        .alu_b_sel     (alu_b_sel),

        .reg_write     (reg_write),
        .illegal_instr (illegal_instr)
    );


    //--------------------------------------------------
    // Expected decoder outputs
    typedef struct packed {
        alu_op_t     alu_op;
        imm_sel_t    imm_sel;
        wb_sel_t     wb_sel;
        mem_op_t     mem_op;
        pc_sel_t     pc_sel;
        branch_op_t  branch_op;
        alu_a_sel_t  alu_a_sel;
        alu_b_sel_t  alu_b_sel;

        logic        reg_write;
        logic        illegal_instr;
    } decode_expected_t;


    //--------------------------------------------------
    // Which outputs matter for a particular test
    typedef struct packed {
        logic alu_op;
        logic imm_sel;
        logic wb_sel;
        logic mem_op;
        logic pc_sel;
        logic branch_op;
        logic alu_a_sel;
        logic alu_b_sel;

        logic reg_write;
        logic illegal_instr;
    } decode_mask_t;


    decode_expected_t expected;
    decode_mask_t     mask;


    //--------------------------------------------------
    // Instruction encoding helpers

    function automatic logic [31:0] encode_r(
        input logic [6:0] funct7_in,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3_in,
        input logic [4:0] rd,
        input logic [6:0] opcode_in
    );
        encode_r = {
            funct7_in,
            rs2,
            rs1,
            funct3_in,
            rd,
            opcode_in
        };
    endfunction


    function automatic logic [31:0] encode_i(
        input logic [11:0] immediate,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3_in,
        input logic [4:0]  rd,
        input logic [6:0]  opcode_in
    );
        encode_i = {
            immediate,
            rs1,
            funct3_in,
            rd,
            opcode_in
        };
    endfunction


    function automatic logic [31:0] encode_s(
        input logic [11:0] immediate,
        input logic [4:0]  rs2,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3_in,
        input logic [6:0]  opcode_in
    );
        encode_s = {
            immediate[11:5],
            rs2,
            rs1,
            funct3_in,
            immediate[4:0],
            opcode_in
        };
    endfunction


    function automatic logic [31:0] encode_b(
        input logic [12:0] immediate,
        input logic [4:0]  rs2,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3_in,
        input logic [6:0]  opcode_in
    );
        encode_b = {
            immediate[12],
            immediate[10:5],
            rs2,
            rs1,
            funct3_in,
            immediate[4:1],
            immediate[11],
            opcode_in
        };
    endfunction


    function automatic logic [31:0] encode_u(
        input logic [19:0] upper_immediate,
        input logic [4:0]  rd,
        input logic [6:0]  opcode_in
    );
        encode_u = {
            upper_immediate,
            rd,
            opcode_in
        };
    endfunction


    function automatic logic [31:0] encode_j(
        input logic [20:0] immediate,
        input logic [4:0]  rd,
        input logic [6:0]  opcode_in
    );
        encode_j = {
            immediate[20],
            immediate[10:1],
            immediate[11],
            immediate[19:12],
            rd,
            opcode_in
        };
    endfunction


    //--------------------------------------------------
    // Clear expectations between tests
    task automatic clear_expected;
        begin
            expected = '0;
            mask     = '0;
        end
    endtask


    //--------------------------------------------------
    // Common OP expectations
    task automatic expect_op(
        input alu_op_t expected_alu_op
    );
        begin
            clear_expected();

            expected.alu_op        = expected_alu_op;
            expected.wb_sel        = WB_ALU;
            expected.mem_op        = MEM_NONE;
            expected.pc_sel        = PC_SEQ;
            expected.branch_op     = BR_NONE;
            expected.alu_a_sel     = ALU_A_RS1;
            expected.alu_b_sel     = ALU_B_RS2;
            expected.reg_write     = 1'b1;
            expected.illegal_instr = 1'b0;

            mask.alu_op        = 1'b1;
            mask.wb_sel        = 1'b1;
            mask.mem_op        = 1'b1;
            mask.pc_sel        = 1'b1;
            mask.branch_op     = 1'b1;
            mask.alu_a_sel     = 1'b1;
            mask.alu_b_sel     = 1'b1;
            mask.reg_write     = 1'b1;
            mask.illegal_instr = 1'b1;
        end
    endtask


    //--------------------------------------------------
    // Common OP-IMM expectations
    task automatic expect_op_imm(
        input alu_op_t expected_alu_op
    );
        begin
            clear_expected();

            expected.alu_op        = expected_alu_op;
            expected.imm_sel       = IMM_I;
            expected.wb_sel        = WB_ALU;
            expected.mem_op        = MEM_NONE;
            expected.pc_sel        = PC_SEQ;
            expected.branch_op     = BR_NONE;
            expected.alu_a_sel     = ALU_A_RS1;
            expected.alu_b_sel     = ALU_B_IMM;
            expected.reg_write     = 1'b1;
            expected.illegal_instr = 1'b0;

            mask.alu_op        = 1'b1;
            mask.imm_sel       = 1'b1;
            mask.wb_sel        = 1'b1;
            mask.mem_op        = 1'b1;
            mask.pc_sel        = 1'b1;
            mask.branch_op     = 1'b1;
            mask.alu_a_sel     = 1'b1;
            mask.alu_b_sel     = 1'b1;
            mask.reg_write     = 1'b1;
            mask.illegal_instr = 1'b1;
        end
    endtask


    //--------------------------------------------------
    // Common LOAD expectations
    task automatic expect_load(
        input mem_op_t expected_mem_op
    );
        begin
            clear_expected();

            expected.alu_op        = ALU_ADD;
            expected.imm_sel       = IMM_I;
            expected.wb_sel        = WB_MEM;
            expected.mem_op        = expected_mem_op;
            expected.pc_sel        = PC_SEQ;
            expected.branch_op     = BR_NONE;
            expected.alu_a_sel     = ALU_A_RS1;
            expected.alu_b_sel     = ALU_B_IMM;
            expected.reg_write     = 1'b1;
            expected.illegal_instr = 1'b0;

            mask = '1;
        end
    endtask


    //--------------------------------------------------
    // Common STORE expectations
    task automatic expect_store(
        input mem_op_t expected_mem_op
    );
        begin
            clear_expected();

            expected.alu_op        = ALU_ADD;
            expected.imm_sel       = IMM_S;
            expected.mem_op        = expected_mem_op;
            expected.pc_sel        = PC_SEQ;
            expected.branch_op     = BR_NONE;
            expected.alu_a_sel     = ALU_A_RS1;
            expected.alu_b_sel     = ALU_B_IMM;
            expected.reg_write     = 1'b0;
            expected.illegal_instr = 1'b0;

            mask.alu_op        = 1'b1;
            mask.imm_sel       = 1'b1;

            // wb_sel is a genuine don't-care for stores.

            mask.mem_op        = 1'b1;
            mask.pc_sel        = 1'b1;
            mask.branch_op     = 1'b1;
            mask.alu_a_sel     = 1'b1;
            mask.alu_b_sel     = 1'b1;
            mask.reg_write     = 1'b1;
            mask.illegal_instr = 1'b1;
        end
    endtask


    //--------------------------------------------------
    // Common BRANCH expectations
    task automatic expect_branch(
        input branch_op_t expected_branch_op
    );
        begin
            clear_expected();

            expected.imm_sel       = IMM_B;
            expected.mem_op        = MEM_NONE;
            expected.pc_sel        = PC_BRANCH;
            expected.branch_op     = expected_branch_op;
            expected.reg_write     = 1'b0;
            expected.illegal_instr = 1'b0;

            // ALU controls and wb_sel are not architecturally
            // meaningful for our dedicated branch-comparison path.

            mask.imm_sel       = 1'b1;
            mask.mem_op        = 1'b1;
            mask.pc_sel        = 1'b1;
            mask.branch_op     = 1'b1;
            mask.reg_write     = 1'b1;
            mask.illegal_instr = 1'b1;
        end
    endtask


    //--------------------------------------------------
    // JAL expectations
    task automatic expect_jal;
        begin
            clear_expected();

            expected.imm_sel       = IMM_J;
            expected.wb_sel        = WB_PC4;
            expected.mem_op        = MEM_NONE;
            expected.pc_sel        = PC_JAL;
            expected.branch_op     = BR_NONE;
            expected.reg_write     = 1'b1;
            expected.illegal_instr = 1'b0;

            mask.imm_sel       = 1'b1;
            mask.wb_sel        = 1'b1;
            mask.mem_op        = 1'b1;
            mask.pc_sel        = 1'b1;
            mask.branch_op     = 1'b1;
            mask.reg_write     = 1'b1;
            mask.illegal_instr = 1'b1;
        end
    endtask


    //--------------------------------------------------
    // JALR expectations
    task automatic expect_jalr;
        begin
            clear_expected();

            expected.alu_op        = ALU_ADD;
            expected.imm_sel       = IMM_I;
            expected.wb_sel        = WB_PC4;
            expected.mem_op        = MEM_NONE;
            expected.pc_sel        = PC_JALR;
            expected.branch_op     = BR_NONE;
            expected.alu_a_sel     = ALU_A_RS1;
            expected.alu_b_sel     = ALU_B_IMM;
            expected.reg_write     = 1'b1;
            expected.illegal_instr = 1'b0;

            mask = '1;
        end
    endtask


    //--------------------------------------------------
    // LUI expectations
    task automatic expect_lui;
        begin
            clear_expected();

            expected.imm_sel       = IMM_U;
            expected.wb_sel        = WB_IMM;
            expected.mem_op        = MEM_NONE;
            expected.pc_sel        = PC_SEQ;
            expected.branch_op     = BR_NONE;
            expected.reg_write     = 1'b1;
            expected.illegal_instr = 1'b0;

            // ALU inputs/op are genuine don't-cares.

            mask.imm_sel       = 1'b1;
            mask.wb_sel        = 1'b1;
            mask.mem_op        = 1'b1;
            mask.pc_sel        = 1'b1;
            mask.branch_op     = 1'b1;
            mask.reg_write     = 1'b1;
            mask.illegal_instr = 1'b1;
        end
    endtask


    //--------------------------------------------------
    // AUIPC expectations
    task automatic expect_auipc;
        begin
            clear_expected();

            expected.alu_op        = ALU_ADD;
            expected.imm_sel       = IMM_U;
            expected.wb_sel        = WB_ALU;
            expected.mem_op        = MEM_NONE;
            expected.pc_sel        = PC_SEQ;
            expected.branch_op     = BR_NONE;
            expected.alu_a_sel     = ALU_A_PC;
            expected.alu_b_sel     = ALU_B_IMM;
            expected.reg_write     = 1'b1;
            expected.illegal_instr = 1'b0;

            mask = '1;
        end
    endtask


    //--------------------------------------------------
    // Illegal instruction expectation
    task automatic expect_illegal;
        begin
            clear_expected();

            expected.reg_write     = 1'b0;
            expected.illegal_instr = 1'b1;

            mask.reg_write     = 1'b1;
            mask.illegal_instr = 1'b1;
        end
    endtask


    //--------------------------------------------------
    // Apply instruction and compare selected outputs
    task automatic check_decode(
        input logic [31:0] instruction_in,
        input string       test_name
    );
        begin
            instruction = instruction_in;
            #1;

            //--------------------------------------------------
            // Decoder should never leak X values.
            assert (!$isunknown({
                alu_op,
                imm_sel,
                wb_sel,
                mem_op,
                pc_sel,
                branch_op,
                alu_a_sel,
                alu_b_sel,
                reg_write,
                illegal_instr
            }))
                else $fatal(
                    1,
                    "%s: decoder produced unknown control value",
                    test_name
                );


            //--------------------------------------------------
            if (mask.alu_op)
                assert (alu_op == expected.alu_op)
                    else $fatal(
                        1,
                        "%s: alu_op mismatch",
                        test_name
                    );

            if (mask.imm_sel)
                assert (imm_sel == expected.imm_sel)
                    else $fatal(
                        1,
                        "%s: imm_sel mismatch",
                        test_name
                    );

            if (mask.wb_sel)
                assert (wb_sel == expected.wb_sel)
                    else $fatal(
                        1,
                        "%s: wb_sel mismatch",
                        test_name
                    );

            if (mask.mem_op)
                assert (mem_op == expected.mem_op)
                    else $fatal(
                        1,
                        "%s: mem_op mismatch",
                        test_name
                    );

            if (mask.pc_sel)
                assert (pc_sel == expected.pc_sel)
                    else $fatal(
                        1,
                        "%s: pc_sel mismatch",
                        test_name
                    );

            if (mask.branch_op)
                assert (branch_op == expected.branch_op)
                    else $fatal(
                        1,
                        "%s: branch_op mismatch",
                        test_name
                    );

            if (mask.alu_a_sel)
                assert (alu_a_sel == expected.alu_a_sel)
                    else $fatal(
                        1,
                        "%s: alu_a_sel mismatch",
                        test_name
                    );

            if (mask.alu_b_sel)
                assert (alu_b_sel == expected.alu_b_sel)
                    else $fatal(
                        1,
                        "%s: alu_b_sel mismatch",
                        test_name
                    );

            if (mask.reg_write)
                assert (reg_write == expected.reg_write)
                    else $fatal(
                        1,
                        "%s: reg_write mismatch",
                        test_name
                    );

            if (mask.illegal_instr)
                assert (illegal_instr == expected.illegal_instr)
                    else $fatal(
                        1,
                        "%s: illegal_instr mismatch",
                        test_name
                    );


            //--------------------------------------------------
            // Global safety invariant.
            assert (!illegal_instr || !reg_write)
                else $fatal(
                    1,
                    "%s: illegal instruction asserted reg_write",
                    test_name
                );
        end
    endtask


    //--------------------------------------------------
    // Tests
    initial begin

        instruction = '0;
        clear_expected();


        //==================================================
        // OP
        //==================================================

        expect_op(ALU_ADD);
        check_decode(
            encode_r(
                7'b0000000,
                5'd7,
                5'd6,
                3'b000,
                5'd5,
                OPCODE_OP
            ),
            "ADD"
        );


        expect_op(ALU_SUB);
        check_decode(
            encode_r(
                7'b0100000,
                5'd7,
                5'd6,
                3'b000,
                5'd5,
                OPCODE_OP
            ),
            "SUB"
        );


        expect_op(ALU_SLL);
        check_decode(
            encode_r(
                7'b0000000,
                5'd7,
                5'd6,
                3'b001,
                5'd5,
                OPCODE_OP
            ),
            "SLL"
        );


        expect_op(ALU_SLT);
        check_decode(
            encode_r(
                7'b0000000,
                5'd7,
                5'd6,
                3'b010,
                5'd5,
                OPCODE_OP
            ),
            "SLT"
        );


        expect_op(ALU_SLTU);
        check_decode(
            encode_r(
                7'b0000000,
                5'd7,
                5'd6,
                3'b011,
                5'd5,
                OPCODE_OP
            ),
            "SLTU"
        );


        expect_op(ALU_XOR);
        check_decode(
            encode_r(
                7'b0000000,
                5'd7,
                5'd6,
                3'b100,
                5'd5,
                OPCODE_OP
            ),
            "XOR"
        );


        expect_op(ALU_SRL);
        check_decode(
            encode_r(
                7'b0000000,
                5'd7,
                5'd6,
                3'b101,
                5'd5,
                OPCODE_OP
            ),
            "SRL"
        );


        expect_op(ALU_SRA);
        check_decode(
            encode_r(
                7'b0100000,
                5'd7,
                5'd6,
                3'b101,
                5'd5,
                OPCODE_OP
            ),
            "SRA"
        );


        expect_op(ALU_OR);
        check_decode(
            encode_r(
                7'b0000000,
                5'd7,
                5'd6,
                3'b110,
                5'd5,
                OPCODE_OP
            ),
            "OR"
        );


        expect_op(ALU_AND);
        check_decode(
            encode_r(
                7'b0000000,
                5'd7,
                5'd6,
                3'b111,
                5'd5,
                OPCODE_OP
            ),
            "AND"
        );


        //==================================================
        // OP-IMM
        //==================================================

        expect_op_imm(ALU_ADD);
        check_decode(
            encode_i(
                12'd12,
                5'd6,
                3'b000,
                5'd5,
                OPCODE_OP_IMM
            ),
            "ADDI"
        );


        expect_op_imm(ALU_SLT);
        check_decode(
            encode_i(
                12'd12,
                5'd6,
                3'b010,
                5'd5,
                OPCODE_OP_IMM
            ),
            "SLTI"
        );


        expect_op_imm(ALU_SLTU);
        check_decode(
            encode_i(
                12'd12,
                5'd6,
                3'b011,
                5'd5,
                OPCODE_OP_IMM
            ),
            "SLTIU"
        );


        expect_op_imm(ALU_XOR);
        check_decode(
            encode_i(
                12'd12,
                5'd6,
                3'b100,
                5'd5,
                OPCODE_OP_IMM
            ),
            "XORI"
        );


        expect_op_imm(ALU_OR);
        check_decode(
            encode_i(
                12'd12,
                5'd6,
                3'b110,
                5'd5,
                OPCODE_OP_IMM
            ),
            "ORI"
        );


        expect_op_imm(ALU_AND);
        check_decode(
            encode_i(
                12'd12,
                5'd6,
                3'b111,
                5'd5,
                OPCODE_OP_IMM
            ),
            "ANDI"
        );


        // SLLI: funct7=0000000, shamt=3
        expect_op_imm(ALU_SLL);
        check_decode(
            encode_i(
                {7'b0000000, 5'd3},
                5'd6,
                3'b001,
                5'd5,
                OPCODE_OP_IMM
            ),
            "SLLI"
        );


        // SRLI
        expect_op_imm(ALU_SRL);
        check_decode(
            encode_i(
                {7'b0000000, 5'd3},
                5'd6,
                3'b101,
                5'd5,
                OPCODE_OP_IMM
            ),
            "SRLI"
        );


        // SRAI
        expect_op_imm(ALU_SRA);
        check_decode(
            encode_i(
                {7'b0100000, 5'd3},
                5'd6,
                3'b101,
                5'd5,
                OPCODE_OP_IMM
            ),
            "SRAI"
        );


        //==================================================
        // LOAD
        //==================================================

        expect_load(MEM_LB);
        check_decode(
            encode_i(
                12'd8,
                5'd6,
                3'b000,
                5'd5,
                OPCODE_LOAD
            ),
            "LB"
        );


        expect_load(MEM_LH);
        check_decode(
            encode_i(
                12'd8,
                5'd6,
                3'b001,
                5'd5,
                OPCODE_LOAD
            ),
            "LH"
        );


        expect_load(MEM_LW);
        check_decode(
            encode_i(
                12'd8,
                5'd6,
                3'b010,
                5'd5,
                OPCODE_LOAD
            ),
            "LW"
        );


        expect_load(MEM_LBU);
        check_decode(
            encode_i(
                12'd8,
                5'd6,
                3'b100,
                5'd5,
                OPCODE_LOAD
            ),
            "LBU"
        );


        expect_load(MEM_LHU);
        check_decode(
            encode_i(
                12'd8,
                5'd6,
                3'b101,
                5'd5,
                OPCODE_LOAD
            ),
            "LHU"
        );


        //==================================================
        // STORE
        //==================================================

        expect_store(MEM_SB);
        check_decode(
            encode_s(
                12'd8,
                5'd7,
                5'd6,
                3'b000,
                OPCODE_STORE
            ),
            "SB"
        );


        expect_store(MEM_SH);
        check_decode(
            encode_s(
                12'd8,
                5'd7,
                5'd6,
                3'b001,
                OPCODE_STORE
            ),
            "SH"
        );


        expect_store(MEM_SW);
        check_decode(
            encode_s(
                12'd8,
                5'd7,
                5'd6,
                3'b010,
                OPCODE_STORE
            ),
            "SW"
        );


        //==================================================
        // BRANCH
        //==================================================

        expect_branch(BR_EQ);
        check_decode(
            encode_b(
                13'd8,
                5'd7,
                5'd6,
                3'b000,
                OPCODE_BRANCH
            ),
            "BEQ"
        );


        expect_branch(BR_NE);
        check_decode(
            encode_b(
                13'd8,
                5'd7,
                5'd6,
                3'b001,
                OPCODE_BRANCH
            ),
            "BNE"
        );


        expect_branch(BR_LT);
        check_decode(
            encode_b(
                13'd8,
                5'd7,
                5'd6,
                3'b100,
                OPCODE_BRANCH
            ),
            "BLT"
        );


        expect_branch(BR_GE);
        check_decode(
            encode_b(
                13'd8,
                5'd7,
                5'd6,
                3'b101,
                OPCODE_BRANCH
            ),
            "BGE"
        );


        expect_branch(BR_LTU);
        check_decode(
            encode_b(
                13'd8,
                5'd7,
                5'd6,
                3'b110,
                OPCODE_BRANCH
            ),
            "BLTU"
        );


        expect_branch(BR_GEU);
        check_decode(
            encode_b(
                13'd8,
                5'd7,
                5'd6,
                3'b111,
                OPCODE_BRANCH
            ),
            "BGEU"
        );


        //==================================================
        // JAL
        //==================================================

        expect_jal();
        check_decode(
            encode_j(
                21'd16,
                5'd1,
                OPCODE_JAL
            ),
            "JAL"
        );


        //==================================================
        // JALR
        //==================================================

        expect_jalr();
        check_decode(
            encode_i(
                12'd8,
                5'd6,
                3'b000,
                5'd1,
                OPCODE_JALR
            ),
            "JALR"
        );


        //==================================================
        // LUI
        //==================================================

        expect_lui();
        check_decode(
            encode_u(
                20'hABCDE,
                5'd5,
                OPCODE_LUI
            ),
            "LUI"
        );


        //==================================================
        // AUIPC
        //==================================================

        expect_auipc();
        check_decode(
            encode_u(
                20'h12345,
                5'd5,
                OPCODE_AUIPC
            ),
            "AUIPC"
        );


        //==================================================
        // Illegal encodings
        //==================================================

        // Illegal OP funct7
        expect_illegal();
        check_decode(
            encode_r(
                7'b1111111,
                5'd7,
                5'd6,
                3'b001,
                5'd5,
                OPCODE_OP
            ),
            "Illegal OP funct7"
        );


        // Illegal SLLI upper bits
        expect_illegal();
        check_decode(
            encode_i(
                {7'b1111111, 5'd3},
                5'd6,
                3'b001,
                5'd5,
                OPCODE_OP_IMM
            ),
            "Illegal SLLI encoding"
        );


        // Illegal shift-immediate upper bits
        expect_illegal();
        check_decode(
            encode_i(
                {7'b1111111, 5'd3},
                5'd6,
                3'b101,
                5'd5,
                OPCODE_OP_IMM
            ),
            "Illegal right-shift immediate encoding"
        );


        // Illegal LOAD funct3
        expect_illegal();
        check_decode(
            encode_i(
                12'd8,
                5'd6,
                3'b011,
                5'd5,
                OPCODE_LOAD
            ),
            "Illegal LOAD funct3"
        );


        // Illegal STORE funct3
        expect_illegal();
        check_decode(
            encode_s(
                12'd8,
                5'd7,
                5'd6,
                3'b011,
                OPCODE_STORE
            ),
            "Illegal STORE funct3"
        );


        // Illegal BRANCH funct3
        expect_illegal();
        check_decode(
            encode_b(
                13'd8,
                5'd7,
                5'd6,
                3'b010,
                OPCODE_BRANCH
            ),
            "Illegal BRANCH funct3"
        );


        // JALR only permits funct3=000
        expect_illegal();
        check_decode(
            encode_i(
                12'd8,
                5'd6,
                3'b001,
                5'd1,
                OPCODE_JALR
            ),
            "Illegal JALR funct3"
        );


        // Completely unsupported opcode
        expect_illegal();
        check_decode(
            32'b0000000_00000_00000_000_00000_0000000,
            "Unknown opcode"
        );


        //--------------------------------------------------
        $display("All decoder tests passed");
        $finish;
    end

endmodule