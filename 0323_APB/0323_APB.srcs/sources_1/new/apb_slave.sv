`timescale 1ns / 1ps

module apb_slave (
    input         pclk,
    input         prst_n,
    input  [31:0] paddr,
    input  [31:0] pwdata,
    input         pwrite,
    input         penable,
    input         psel,
    output [31:0] prdata,
    output        pready,
    output        pslverr
);

    

endmodule
