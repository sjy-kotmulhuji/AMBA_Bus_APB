`timescale 1ns / 1ps

module rv32i_top (
    input         clk,
    input         rst,
    input  [ 7:0] gpi,        //Switch 8~15
    input         uart_rx,
    output        uart_tx,
    output [ 7:0] gpo,        //LED 8~15
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data,
    inout  [15:0] gpio        //{LED 0~7, Switch 0~7}
);
    logic bus_wreq, bus_rreq, bus_ready;
    logic [2:0] o_funct3;
    logic [31:0] instr_addr, instr_data;
    logic [31:0] bus_addr, bus_wdata, bus_rdata;
    logic [5:0] psel, pready;
    logic penable, pwrite;
    logic [31:0] prdata[0:5];
    logic [31:0] paddr, pwdata;
    logic [15:0] fnd_out_data;

    instruction_memory U_INSTRUCTION_MEM (.*);

    rv32i_cpu U_RV32I (
        .*,
        .o_funct3(o_funct3)
    );


    //data_mem U_DATA_MEM (
    //    .*,
    //    .i_funct3(o_funct3)
    //);

    apb_master U_APB_MASTER (
        .pclk(clk),
        .prst(rst),

        .wreq (bus_wreq),
        .rreq (bus_rreq),
        .addr (bus_addr),
        .wdata(bus_wdata),

        .slverr(),
        .rdata (bus_rdata),
        .ready (bus_ready),

        .pslverr(),
        .*
    );

    bram U_BRAM (
        .pclk  (clk),
        .*,
        .psel  (psel[0]),
        .prdata(prdata[0]),
        .pready(pready[0])
    );


    GPO U_APB_GPO (
        .pclk   (clk),
        .prst   (rst),
        .*,
        .psel   (psel[1]),
        .prdata (prdata[1]),
        .pready (pready[1]),
        .gpo_out(gpo)
    );

    GPI U_APB_GPI (
        .pclk  (clk),
        .prst  (rst),
        .*,
        .gpi_in({8'd0, gpi}),
        .psel  (psel[2]),
        .pready(pready[2]),
        .prdata(prdata[2])
    );

    GPIO U_APB_GPIO (
        .pclk  (clk),
        .prst  (rst),
        .*,
        .psel  (psel[3]),
        .pready(pready[3]),
        .prdata(prdata[3]),
        .gpio  (gpio)
    );

    FND U_APB_FND (
        .pclk     (clk),
        .prst     (rst),
        .*,
        .psel     (psel[4]),
        .pready   (pready[4]),
        .prdata   (prdata[4]),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    //fnd_controller U_APB_FND_CNTL (
    //    .clk        (clk),
    //    .reset      (rst),
    //    .fnd_in_data(fnd_out_data[13:0]),
    //    .fnd_digit  (fnd_digit),
    //    .fnd_data   (fnd_data)
    //);

    UART U_APB_UART (
        .pclk   (clk),
        .prst   (rst),
        .*,
        .psel   (psel[5]),
        .prdata (prdata[5]),
        .pready (pready[5]),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

endmodule
