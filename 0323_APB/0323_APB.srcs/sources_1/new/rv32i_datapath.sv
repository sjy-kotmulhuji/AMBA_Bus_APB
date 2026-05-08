`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input         clk,
    input         rst,
    input         pc_en,
    input         rf_we,
    input         alu_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    input  [31:0] bus_rdata,    //변경
    input  [ 2:0] rfwd_src,
    input         branch,
    input         jal,
    input         jalr,
    output [31:0] instr_addr,
    output [31:0] bus_addr, //변경
    output [31:0] bus_wdata //변경
);
    logic [31:0] rd1, rd2, alu_result, imm_data, alurs2_data;
    logic [31:0] rfwb_data;  //register file write back data
    logic [31:0] pc_alu_4_out, pc_alu_imm_out;
    logic [31:0]
        o_dec_rs1,
        o_dec_rs2,
        o_dec_imm,
        //o_exe_imm,
        o_exe_rs2,
        //o_exe_pc_4,
        //o_exe_pc_imm,
        o_exe_alu_result,
        o_mem_bus_rdata;
    logic btaken;

    assign bus_addr  = o_exe_alu_result;
    assign bus_wdata = o_exe_rs2;

    program_counter U_PC (
        .clk            (clk),
        .rst            (rst),
        .pc_en          (pc_en),
        .imm_data       (imm_data),
        .btaken         (btaken),
        .branch         (branch),
        .jal            (jal),
        .jalr           (jalr),
        .rd1            (o_dec_rs1),
        .pc_alu_4_out   (pc_alu_4_out),
        .pc_alu_imm_out (pc_alu_imm_out),
        .program_counter(instr_addr)
    );

    //register U_EXE_PC_4 (   //얘네도 없어도 될 듯??
    //    .clk     (clk),
    //    .rst     (rst),
    //    .data_in (pc_alu_4_out),
    //    .data_out(o_exe_pc_4)
    //);
//
    //register U_EXE_PC_IMM ( //얘네도 없어도 될 듯??
    //    .clk     (clk),
    //    .rst     (rst),
    //    .data_in (pc_alu_imm_out),
    //    .data_out(o_exe_pc_imm)
    //);

    register_file U_REG_FILE (
        .clk  (clk),
        .rst  (rst),
        .ra1  (instr_data[19:15]),
        .ra2  (instr_data[24:20]),
        .wa   (instr_data[11:7]),
        .wdata(rfwb_data),
        .rf_we(rf_we),
        .rd1  (rd1),
        .rd2  (rd2)
    );

    register U_DEC_REG_RS1 (
        .clk     (clk),
        .rst     (rst),
        .data_in (rd1),
        .data_out(o_dec_rs1)
    );

    register U_DEC_REG_RS2 (
        .clk     (clk),
        .rst     (rst),
        .data_in (rd2),
        .data_out(o_dec_rs2)
    );

    imm_extender U_IMM_EXTEND (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    register U_DEC_IMM_EXT (
        .clk     (clk),
        .rst     (rst),
        .data_in (imm_data),
        .data_out(o_dec_imm)
    );

    //register U_EXE_IMM_WB (  //LUI IMM EXECUTE -> WB
    //    .clk     (clk),
    //    .rst     (rst),
    //    .data_in (o_dec_imm),
    //    .data_out(o_exe_imm)
    //);

    mux_2x1 U_MUX_ALUSRC_RS2 (
        .in0    (o_dec_rs2),
        .in1    (o_dec_imm),
        .mux_sel(alu_src),
        .out_mux(alurs2_data)
    );

    register U_EXE_REG_RS2 (
        .clk     (clk),
        .rst     (rst),
        .data_in (o_dec_rs2),
        .data_out(o_exe_rs2)
    );

    alu U_ALU (
        .rd1        (o_dec_rs1),
        .rd2        (alurs2_data),
        .alu_control(alu_control),
        .alu_result (alu_result),
        .btaken     (btaken)
    );

    register U_EXE_ALU_RESULT (
        .clk     (clk),
        .rst     (rst),
        .data_in (alu_result),
        .data_out(o_exe_alu_result)
    );

    register U_REG_bus_rdata (
        .clk     (clk),
        .rst     (rst),
        .data_in (bus_rdata),
        .data_out(o_mem_bus_rdata)
    );

    mux_5x1 U_WB_REGFILE (
        .alu_result(alu_result),
        .bus_rdata    (o_mem_bus_rdata),
        .imm       (o_dec_imm), //LUI WB 단계 생략해서 EXE -> WB Register 필요없음
        .pc_imm    (pc_alu_imm_out),    //얘도
        .pc_4      (pc_alu_4_out),  //얘도
        .rfwd_src  (rfwd_src),
        .out_mux   (rfwb_data)
    );
endmodule

module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] ra1,    //instruction code rs1
    input  [ 4:0] ra2,    //instruction code rs2
    input  [ 4:0] wa,
    input  [31:0] wdata,
    input         rf_we,
    output [31:0] rd1,
    output [31:0] rd2
);
    logic [31:0] register_file[1:31];  //0       0

`ifdef SIMULATION
    initial begin
        for (int i = 0; i < 31; i++) begin
            register_file[i] = i;
        end
        register_file[31] = 32'hFF00000F;   //Signed Decimal: -2,147,483,647, Unsigned Decimal: 2,147,483,649


        //register_file[31] = 32'h80000001;   //Signed Decimal: -2,147,483,647, Unsigned Decimal: 2,147,483,649
    end
`endif

    always_ff @(posedge clk) begin
        if (!rst & rf_we) begin
            register_file[wa] <= wdata;
        end

    end

    //output CL
    assign rd1 = (ra1 == 0) ? 0 : register_file[ra1];
    assign rd2 = (ra2 == 0) ? 0 : register_file[ra2];

endmodule

module alu (
    input        [31:0] rd1,          //RS1
    input        [31:0] rd2,          //RS2
    input        [ 3:0] alu_control,  //funct7[6], funct3 : 4bit
    output logic [31:0] alu_result,
    output logic        btaken
);
    always_comb begin
        alu_result = 0;
        case (alu_control)
            `ADD: alu_result = rd1 + rd2;  //add(RD = RS1 + RS2)
            `SUB: alu_result = rd1 - rd2;  //sub
            `SLL: alu_result = rd1 << rd2[4:0];  //sll
            `SLT:
            alu_result = ($signed(rd1) < $signed(rd2)) ? 1 : 0;  //slt( 񱳱 )
            `SLTU: alu_result = (rd1 < rd2) ? 1 : 0;  //sltu(unsigned   )
            `XOR: alu_result = rd1 ^ rd2;  //xor
            `SRL: alu_result = rd1 >> rd2[4:0];  //srl
            `SRA:
            alu_result = $signed(rd1) >>>
                rd2[4:0];  //srl(msb extention) msb Ȯ  
            `OR: alu_result = rd1 | rd2;  //||  ƴ .(      񱳰   ƴ       )
            `AND: alu_result = rd1 & rd2;  //&&  ƴ .
        endcase
    end

    always_comb begin
        btaken = 0;
        case (alu_control)
            `BEQ: begin
                if (rd1 == rd2) btaken = 1;
                else btaken = 0;
            end
            `BNE: begin
                if (rd1 != rd2) btaken = 1;
                else btaken = 0;
            end
            `BLT: begin
                if ($signed(rd1) < $signed(rd2)) btaken = 1;
                else btaken = 0;
            end
            `BGE: begin
                if ($signed(rd1) >= $signed(rd2)) btaken = 1;
                else btaken = 0;
            end
            `BLTU: begin  // zero extension Unsigned
                if (rd1 < rd2) btaken = 1;
                else btaken = 0;
            end
            `BGEU: begin  //zero extension
                if (rd1 >= rd2) btaken = 1;
                else btaken = 0;
            end
        endcase
    end
endmodule

module program_counter (
    input         clk,
    input         rst,
    input         pc_en,
    input  [31:0] imm_data,
    input         btaken,
    input         branch,
    input         jal,
    input         jalr,
    input  [31:0] rd1,
    output [31:0] pc_alu_4_out,
    output [31:0] pc_alu_imm_out,
    output [31:0] program_counter
);
    logic [31:0] pc_mux_out, pc_rd1_mux_out, o_exe_pc_next;
    logic pc_mux_sel;

    assign pc_mux_sel = (branch & btaken) | jal;

    mux_2x1 U_PC_rs1_MUX (
        .in0    (program_counter),
        .in1    (rd1),
        .mux_sel(jalr),
        .out_mux(pc_rd1_mux_out)
    );

    pc_alu U_PC_ALU_IMM (
        .a         (imm_data),
        .b         (pc_rd1_mux_out),
        .pc_alu_out(pc_alu_imm_out)
    );

    pc_alu U_PC_ALU_4 (
        .a         (32'd4),
        .b         (program_counter),
        .pc_alu_out(pc_alu_4_out)
    );

    mux_2x1 U_PC_MUX (
        .in0    (pc_alu_4_out),
        .in1    (pc_alu_imm_out),
        .mux_sel(pc_mux_sel),
        .out_mux(pc_mux_out)
    );

    register U_PC_NEXT_REG (
        .clk     (clk),
        .rst     (rst),
        .data_in (pc_mux_out),
        .data_out(o_exe_pc_next)
    );

    register_en U_PC_REG (
        .clk     (clk),
        .rst     (rst),
        .pc_en   (pc_en),
        .data_in (o_exe_pc_next),
        .data_out(program_counter)
    );

endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);
    assign pc_alu_out = a + b;

endmodule

module register (
    input         clk,
    input         rst,
    input  [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end
    assign data_out = register;

endmodule

module register_en (
    input         clk,
    input         rst,
    input         pc_en,
    input  [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            if (pc_en) register <= data_in;
        end
    end
    assign data_out = register;

endmodule


module imm_extender (
    input        [31:0] instr_data,
    output logic [31:0] imm_data
);

    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])
            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end
            `I_TYPE, `IL_TYPE, `JL_TYPE: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
            `B_TYPE: begin
                imm_data = {
                    {19{instr_data[31]}},
                    instr_data[31],
                    instr_data[7],
                    instr_data[30:25],
                    instr_data[11:8],
                    1'b0
                };
            end
            `UL_TYPE, `U_TYPE: begin
                imm_data = {instr_data[31:12], 12'b0};
            end
            `J_TYPE: begin
                imm_data = {
                    {11{instr_data[31]}},
                    instr_data[31],
                    instr_data[19:12],
                    instr_data[20],
                    instr_data[30:21],
                    1'b0
                };
            end
        endcase
    end
endmodule


module mux_2x1 (
    input  [31:0] in0,
    input  [31:0] in1,
    input         mux_sel,
    output [31:0] out_mux
);

    assign out_mux = (mux_sel) ? in1 : in0;

endmodule

module mux_5x1 (
    input        [31:0] alu_result,  //R-Type  
    input        [31:0] bus_rdata,      //I-Type
    input        [31:0] imm,         //LUI
    input        [31:0] pc_imm,      //AUIPC
    input        [31:0] pc_4,        //JAL/JALR
    input        [ 2:0] rfwd_src,
    output logic [31:0] out_mux
);

    always_comb begin
        case (rfwd_src)
            3'b000:  out_mux = alu_result;
            3'b001:  out_mux = bus_rdata;
            3'b010:  out_mux = imm;
            3'b011:  out_mux = pc_imm;
            3'b100:  out_mux = pc_4;
            default: out_mux = 0;
        endcase
    end

endmodule
