`timescale 1ns / 1ps

module GPIO (
    input               pclk,
    input               prst,
    input        [31:0] paddr,
    input        [31:0] pwdata,
    input               pwrite,
    input               penable,
    input               psel,
    output logic [31:0] prdata,
    output logic        pready,
    //external port
    inout  logic [15:0] gpio     //{LED 0~7번, Switch 0~7번}
);

    localparam [11:0] gpio_ctl_addr = 12'h000;
    localparam [11:0] gpio_odata_addr = 12'h004;
    localparam [11:0] gpio_idata_addr = 12'h008;

    logic [15:0] gpio_odata_reg, gpio_ctl_reg, gpio_idata_reg;

    assign pready = (penable & psel) ? 1'b1 : 1'b0;

    assign prdata = (paddr[11:0] == gpio_ctl_addr) ? {16'h0000, gpio_ctl_reg} : 
    (paddr[11:0] == gpio_odata_addr) ? {16'h0000, gpio_odata_reg} : (paddr[11:0] == gpio_idata_addr) ? {16'h0000, gpio_idata_reg} : 32'hxxxx_xxxx;

    always_ff @(posedge pclk, posedge prst) begin
        if (prst) begin
            gpio_odata_reg <= 16'd0;
            gpio_ctl_reg   <= 16'd0;
            //gpio_idata_reg <= 16'd0;
        end else begin
            if (pready) begin
                if(pwrite) begin
                case (paddr[11:0])
                    gpio_ctl_addr: begin
                        gpio_ctl_reg <= pwdata[15:0];
                    end
                    gpio_odata_addr: begin
                        gpio_odata_reg <= pwdata[15:0];
                    end
                   // gpio_idata_addr: begin
                   //     gpio_idata_reg <= pwdata[15:0];
                   // end
                endcase
                end 
            end
        end
    end

    gpio_control U_GPIO_CTL (
        .ctl   (gpio_ctl_reg),
        .o_data(gpio_odata_reg),
        .i_data(gpio_idata_reg),
        .gpio  (gpio)
    );


endmodule

module gpio_control (
    input        [15:0] ctl,
    input        [15:0] o_data,
    output logic [15:0] i_data,
    inout  logic [15:0] gpio
);

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign gpio[i]   = (ctl[i]) ? o_data[i] : 1'bz;
            assign i_data[i] = (~ctl[i]) ? gpio[i] : 1'bz;
        end
    endgenerate

endmodule
