`timescale 1ns / 1ps


module tb_apb_master ();
    logic clk, rst_n, wreq, rreq, pwrite, penable, ready;
    logic [5:0] psel, pready;
    logic [31:0] addr, paddr, rdata, wdata, pwdata;

    logic        slverr;

    logic [ 5:0] pslverr;
    logic [31:0] prdata  [0:5];




    apb_master dut (
        .pclk  (clk),
        .prst_n(rst_n),

        .wreq (wreq),
        .rreq (rreq),
        .addr (addr),
        .wdata(wdata),

        .slverr(slverr),
        .rdata (rdata),
        .ready (ready),

        .pslverr(pslverr),
        .prdata (prdata),
        .pready (pready),

        .psel   (psel),
        .paddr  (paddr),
        .pwdata (pwdata),
        .penable(penable),
        .pwrite (pwrite)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        ready = 0;

        #20;
        rst_n = 1;

        @(posedge clk);
        #1;
        wreq  = 1;
        addr  = 32'h1000_0000;
        wdata = 32'h0000_0041;

        @(psel[0] && penable);
        @(posedge clk);
        pready[0] = 1'b1;

        @(posedge clk);
        #1;
        pready[0] = 1'b0;

        //@(posedge clk);
        wreq = 0;

        //UART Verification
        @(posedge clk);
        #1;
        rreq = 1'b1;
        addr = 32'h2000_4000;
        

        @(psel[5] && penable);
        @(posedge clk);
        @(posedge clk);
        #1;
        pready[5] = 1'b1;
        prdata[5] = 32'h0000_0042;

        @(posedge clk);
        #1;
        pready[5] = 1'b0;
        rreq = 1'b0;

        @(posedge clk);
        @(posedge clk);
        $stop;





    end

endmodule
