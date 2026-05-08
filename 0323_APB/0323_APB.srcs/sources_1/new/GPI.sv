`timescale 1ns / 1ps

module GPI (
    input         pclk,
    input         prst,
    input         pwrite,
    input         penable,
    input         psel,
    input  [31:0] paddr,
    input  [15:0] gpi_in,
    input  [31:0] pwdata,
    output        pready,
    output [31:0] prdata
);

    localparam [11:0] gpi_ctl_addr = 12'h000;
    localparam [11:0] gpi_idata_addr = 12'h004;

    logic [15:0] gpi_ctl_reg, gpi_idata_reg;

    assign pready = (psel && penable) ? 1'b1 : 1'b0;
    assign prdata = (paddr[11:0] == gpi_ctl_addr) ? {16'h0000, gpi_ctl_reg} : (paddr[11:0] == gpi_idata_addr) ? {16'h0000, gpi_idata_reg} : 32'hxxxx_xxxx;


    always_ff @(posedge pclk, posedge prst) begin
        if (prst) begin
            gpi_ctl_reg <= 16'd0;
        end else begin
            if (pready) begin
                case (paddr[11:0])
                    gpi_ctl_addr: begin
                        gpi_ctl_reg <= pwdata[15:0];
                    end
                endcase
            end
        end
    end

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign gpi_idata_reg[i] = (gpi_ctl_reg[i]) ? gpi_in[i] : 1'bz;
        end
    endgenerate

endmodule
