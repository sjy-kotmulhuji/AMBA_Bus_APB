`timescale 1ns / 1ps


module apb_mux (
    input        [31:0] prdata0,
    input        [31:0] prdata1,
    input        [31:0] prdata2,
    input        [31:0] prdata3,
    input        [31:0] prdata4,
    input        [31:0] prdata5,
    input               pready0,
    input               pready1,
    input               pready2,
    input               pready3,
    input               pready4,
    input               pready5,
    input        [ 2:0] sel,            //slv_num
    output logic [31:0] mux_out_rdata,
    output logic        mux_out_ready
);
    always_comb begin
        mux_out_rdata = 32'd0;
        mux_out_ready = 1'b0;
        case (sel)
            3'd0: begin
                mux_out_rdata = prdata0;
                mux_out_ready = pready0;
            end
            3'd1: begin
                mux_out_rdata = prdata1;
                mux_out_ready = pready1;
            end
            3'd2: begin
                mux_out_rdata = prdata2;
                mux_out_ready = pready2;
            end
            3'd3: begin
                mux_out_rdata = prdata3;
                mux_out_ready = pready3;
            end
            3'd4: begin
                mux_out_rdata = prdata4;
                mux_out_ready = pready4;
            end
            3'd5: begin
                mux_out_rdata = prdata5;
                mux_out_ready = pready5;
            end
        endcase
    end

endmodule
