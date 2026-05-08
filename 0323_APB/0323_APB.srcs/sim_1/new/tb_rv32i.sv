`timescale 1ns / 1ps

module tb_rv32i ();
    logic clk, rst;
    logic [ 7:0] gpi;
    logic [ 7:0] gpo;
    logic        uart_rx;
    logic        uart_tx;
    logic [ 7:0] fnd_data;
    logic [ 3:0] fnd_digit;
    wire  [15:0] gpio;

    integer i;
    parameter Baud = (100_000_000 / 9600) * 10;

    rv32i_top dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        //gpi = 8'h00;
        //gpio = 16'h0000;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        //gpi = 8'haa;
      //  #4000000;
      //  
      //  for(i=0; i<8; i++) begin
      //      uart_rx = i;
      //      #(Baud);
      //  end
//
      //  uart_rx = 1;
//
      //  #3000;
        repeat (2000) @(negedge clk);
        $stop;
    end
endmodule