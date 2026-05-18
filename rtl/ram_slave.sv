`timescale 1ns / 1ps

module bram (
    //RAM Slave <-> APB Master
    input         pclk,
    input  [31:0] paddr,
    input  [31:0] pwdata,
    input         pwrite,
    input         penable,
    input         psel,
    output [31:0] prdata,
    output        pready
);
    logic [31:0] bmem[0:1024];

    assign pready = (penable & psel) ? 1'b1 : 1'b0;

    assign daddr  = paddr;

    always_ff @(posedge pclk) begin
        if (psel && penable && pwrite) begin
            bmem[paddr[11:2]] <= pwdata;
        end
    end

    assign prdata = bmem[paddr[11:2]];

    //always_comb begin
    //    pready = 1'b0;
    //    if (psel && penable) begin
    //        if (pwrite) begin  //write
    //            dwdata = pwdata;
    //            pready = 1'b1;
    //        end else begin  //read
    //            prdata = drdata;
    //            pready = 1'b1;
    //        end
    //    end
    //end


endmodule



//output        pslverr,

//RAM SLAVE <-> RAM
//input        [31:0] drdata,
//output logic [31:0] daddr,
//output logic [31:0] dwdata,
//output logic        dwe
