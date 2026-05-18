`timescale 1ns / 1ps


module addr_decoder (
    input               en,
    input        [31:0] addr,
    output logic [ 5:0] psel,    //RAM, GPO, GPI, GPIO, FND, UART
    output logic [ 2:0] slv_num
);
    always_comb begin
        psel = 6'd0;
        slv_num = 0;
        if (en) begin
            case (addr[31:28])
                4'h1: slv_num = 0;
                4'h2: begin
                    case (addr[15:12])
                        4'h0: slv_num = 1;
                        4'h1: slv_num = 2;
                        4'h2: slv_num = 3;
                        4'h3: slv_num = 4;
                        4'h4: slv_num = 5;
                    endcase
                end
            endcase
            psel[slv_num] = 1'b1;
        end
    end
endmodule
