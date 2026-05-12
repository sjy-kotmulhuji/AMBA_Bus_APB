`timescale 1ns / 1ps

module GPO (
    input         pclk,
    input         prst,
    input  [31:0] paddr,
    input  [31:0] pwdata,
    input         pwrite,
    input         penable,
    input         psel,
    output [31:0] prdata,
    output        pready,
    output [15:0] gpo_out
);
    localparam [11:0] gpo_ctl_addr = 12'h000;
    localparam [11:0] gpo_odata_addr = 12'h004;

    logic [15:0] gpo_odata_reg, gpo_ctl_reg;

    //assign gpo_out = (gpo_ctl_reg) ? gpo_odata_reg : 16'hzzzz;

    assign pready = (penable & psel) ? 1'b1 : 1'b0;
    assign prdata = (paddr[11:0] == gpo_ctl_addr) ? {16'h0000, gpo_ctl_reg} : 
    (paddr[11:0] == gpo_odata_addr) ? {16'h0000, gpo_odata_reg} : 32'hxxxx_xxxx;

    always_ff @(posedge pclk, posedge prst) begin
        if (prst) begin
            gpo_odata_reg <= 16'd0;
            gpo_ctl_reg   <= 16'd0;
        end else begin
            if (pready && pwrite) begin
                case (paddr[11:0])
                    gpo_ctl_addr: begin
                        gpo_ctl_reg <= pwdata[15:0];
                    end
                    gpo_odata_addr: begin
                        gpo_odata_reg <= pwdata[15:0];
                    end
                endcase
            end
        end
    end

    //control 신호 한 bit씩 제어하기 위한 반복문
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign gpo_out[i] = (gpo_ctl_reg[i]) ? gpo_odata_reg[i] : 1'bz;
        end
    endgenerate
endmodule
