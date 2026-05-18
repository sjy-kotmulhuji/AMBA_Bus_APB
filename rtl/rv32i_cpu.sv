`timescale 1ns / 1ps
`include "define.vh"

module rv32i_cpu (
    input         clk,
    input         rst,
    input  [31:0] instr_data,
    input  [31:0] bus_rdata,   //name changed drdata -> bus_rdata
    input         bus_ready,   //new!
    output [31:0] instr_addr,  //name changed daddr -> bus_addr
    output        bus_wreq,
    output        bus_rreq,    //new!
    output [ 2:0] o_funct3,    //??     
    output [31:0] bus_addr,    //name changed daddr -> bus_addr
    output [31:0] bus_wdata    //name changed dwdata -> bus_wdata
);

    logic rf_we, branch, pc_en;
    logic [3:0] alu_control;
    logic [2:0] rfwd_src;
    logic       alu_src;

    control_unit U_CONTROL_UNIT (
        .clk        (clk),
        .rst        (rst),
        .funct7     (instr_data[31:25]),
        .funct3     (instr_data[14:12]),
        .opcode     (instr_data[6:0]),
        .ready      (bus_ready),
        .pc_en      (pc_en),
        .rf_we      (rf_we),
        .branch     (branch),
        .jal        (jal),
        .jalr       (jalr),
        .alu_src    (alu_src),
        .alu_control(alu_control),
        .rfwd_src   (rfwd_src),
        .o_funct3   (o_funct3),
        .dwe        (bus_wreq),
        .dre        (bus_rreq)
    );

    rv32i_datapath U_DATAPATH (.*);

endmodule


