`timescale 1ns/1ps

module imm_gen_tb;

    import riscv_pkg::*;

    typedef logic signed [11:0] imm12_t;
    typedef logic signed [12:0] imm13_t;
    typedef logic signed [20:0] imm21_t;

    logic [31:0] instr;
    imm_sel_t    imm_sel;
    logic [31:0] imm;

    imm12_t test_imm12;
    imm13_t test_imm13;
    imm21_t test_imm21;

    imm_gen dut (
        .instr   (instr),
        .imm_sel (imm_sel),
        .imm     (imm)
    );

    initial begin
        instr      = '0;
        imm_sel    = IMM_I;
        test_imm12 = '0;
        test_imm13 = '0;
        test_imm21 = '0;

        //--------------------------------------------------
        // I-type: positive immediate
        instr = '0;
        test_imm12 = imm12_t'(12);

        instr[31:20] = test_imm12;
        imm_sel = IMM_I;
        #1;

        assert ($signed(imm) == 32'sd12)
            else $fatal(1, "I-type +12 failed");


        //--------------------------------------------------
        // I-type: negative immediate
        instr = '0;
        test_imm12 = imm12_t'(-4);

        instr[31:20] = test_imm12;
        imm_sel = IMM_I;
        #1;

        assert ($signed(imm) == -32'sd4)
            else $fatal(1, "I-type -4 failed");


        //--------------------------------------------------
        // I-type: minimum signed immediate
        instr = '0;
        test_imm12 = imm12_t'(-2048);

        instr[31:20] = test_imm12;
        imm_sel = IMM_I;
        #1;

        assert ($signed(imm) == -32'sd2048)
            else $fatal(1, "I-type minimum failed");


        //--------------------------------------------------
        // S-type: positive immediate
        instr = '0;
        test_imm12 = imm12_t'(20);

        instr[31:25] = test_imm12[11:5];
        instr[11:7]  = test_imm12[4:0];
        imm_sel = IMM_S;
        #1;

        assert ($signed(imm) == 32'sd20)
            else $fatal(1, "S-type +20 failed");


        //--------------------------------------------------
        // S-type: negative immediate
        instr = '0;
        test_imm12 = imm12_t'(-8);

        instr[31:25] = test_imm12[11:5];
        instr[11:7]  = test_imm12[4:0];
        imm_sel = IMM_S;
        #1;

        assert ($signed(imm) == -32'sd8)
            else $fatal(1, "S-type -8 failed");


        //--------------------------------------------------
        // B-type: positive immediate
        instr = '0;
        test_imm13 = imm13_t'(16);

        instr[31]    = test_imm13[12];
        instr[7]     = test_imm13[11];
        instr[30:25] = test_imm13[10:5];
        instr[11:8]  = test_imm13[4:1];
        imm_sel = IMM_B;
        #1;

        assert ($signed(imm) == 32'sd16)
            else $fatal(1, "B-type +16 failed");


        //--------------------------------------------------
        // B-type: negative immediate
        instr = '0;
        test_imm13 = imm13_t'(-16);

        instr[31]    = test_imm13[12];
        instr[7]     = test_imm13[11];
        instr[30:25] = test_imm13[10:5];
        instr[11:8]  = test_imm13[4:1];
        imm_sel = IMM_B;
        #1;

        assert ($signed(imm) == -32'sd16)
            else $fatal(1, "B-type -16 failed");


        //--------------------------------------------------
        // U-type
        instr = '0;

        instr[31:12] = 20'hABCDE;
        imm_sel = IMM_U;
        #1;

        assert (imm == 32'hABCDE000)
            else $fatal(1, "U-type failed");


        //--------------------------------------------------
        // J-type: positive immediate
        instr = '0;
        test_imm21 = imm21_t'(128);

        instr[31]    = test_imm21[20];
        instr[19:12] = test_imm21[19:12];
        instr[20]    = test_imm21[11];
        instr[30:21] = test_imm21[10:1];
        imm_sel = IMM_J;
        #1;

        assert ($signed(imm) == 32'sd128)
            else $fatal(1, "J-type +128 failed");


        //--------------------------------------------------
        // J-type: negative immediate
        instr = '0;
        test_imm21 = imm21_t'(-128);

        instr[31]    = test_imm21[20];
        instr[19:12] = test_imm21[19:12];
        instr[20]    = test_imm21[11];
        instr[30:21] = test_imm21[10:1];
        imm_sel = IMM_J;
        #1;

        assert ($signed(imm) == -32'sd128)
            else $fatal(1, "J-type -128 failed");


        //--------------------------------------------------
        // Zero immediate
        instr = '0;
        imm_sel = IMM_I;
        #1;

        assert (imm == 32'd0)
            else $fatal(1, "Zero immediate failed");


        $display("All imm_gen tests passed");
        $finish;
    end

endmodule