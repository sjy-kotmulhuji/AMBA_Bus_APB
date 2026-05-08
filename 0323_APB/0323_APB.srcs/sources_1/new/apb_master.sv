`timescale 1ns / 1ps

module apb_master (
    input               pclk,
    input               prst,
    //CPU -> Master Input
    input               wreq,    //dwe
    input               rreq,    //dre
    input        [31:0] addr,
    input        [31:0] wdata,
    //Master -> CPU Output
    output logic        slverr,
    output       [31:0] rdata,
    output              ready,   //handshake 방식

    //Slave -> Master Input
    input        [ 5:0] pslverr,
    input        [31:0] prdata [0:5],
    input        [ 5:0] pready,
    //Master -> Slave Output
    output logic [ 5:0] psel,
    output logic [31:0] paddr,
    output logic [31:0] pwdata,
    output logic        penable,
    output logic        pwrite
);

    logic [2:0] slv_num;
    logic       decode_en;  //psel이 setup, access 상태 동안 출력되도록 하는 신호
    logic       pwrite_next;
    logic [31:0] paddr_next, pwdata_next;


    typedef enum {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e c_state, n_state;

    //State Register
    always_ff @(posedge pclk, posedge prst) begin //negedge로 하라니까 해줌,,,별 이유 없음
        if (prst) begin  //reset active low
            c_state <= IDLE;
            paddr   <= 32'd0;
            pwdata  <= 32'd0;
            pwrite  <= 1'b0;
        end else begin
            c_state <= n_state;
            paddr   <= paddr_next;
            pwdata  <= pwdata_next;
            pwrite  <= pwrite_next;
        end
    end

    //Next State CL
    always_comb begin
        paddr_next  = paddr;
        pwdata_next = pwdata;
        pwrite_next = pwrite;
        n_state     = c_state;
        case (c_state)
            IDLE: begin
                paddr_next  = 32'd0;
                pwdata_next = 32'd0;
                pwrite_next = 1'b0;
                if (wreq | rreq) begin
                    paddr_next  = addr;
                    pwdata_next = wdata;
                    if (wreq) begin         //IDLE에서 SETUP 넘어갈 때만 제어해서 SETUP, ACCESS 동안 유지
                        pwrite_next = 1'b1;
                    end else begin
                        pwrite_next = 1'b0;
                    end
                    n_state = SETUP;
                end
            end
            SETUP: begin
                n_state = ACCESS;
            end
            ACCESS: begin
                if (pready[slv_num] == 1'b1) begin  //mux에서 받는 ready로도 대체 가능
                    n_state = IDLE;
                    // if (wreq | rreq) n_state = SETUP;     //일단 생략~~
                    // else n_state = IDLE;  //no transfer
                end
            end
        endcase
    end

    //Output CL
    always_comb begin
        penable   = 1'b0;
        decode_en = 1'b0;
        slverr    = 1'b0;
        case (c_state)
            IDLE: begin
                decode_en = 0;
            end
            SETUP: begin
                decode_en = 1;
                penable   = 1'b0;
                //if (wreq) pwrite = 1'b1;
                //else if (rreq) pwrite = 1'b0;
            end
            ACCESS: begin
                decode_en = 1;
                penable = 1'b1;
                slverr = (pslverr[slv_num]) ? 1 : 0;
            end
        endcase
    end

    addr_decoder U_ADDR_DEC (
        .en     (decode_en),
        .addr   (paddr),      //addr -> paddr 왜왜??
        .psel   (psel),
        .slv_num(slv_num)
    );

    apb_mux U_MUX_RDATA (
        .prdata0      (prdata[0]),
        .prdata1      (prdata[1]),
        .prdata2      (prdata[2]),
        .prdata3      (prdata[3]),
        .prdata4      (prdata[4]),
        .prdata5      (prdata[5]),
        .pready0      (pready[0]),
        .pready1      (pready[1]),
        .pready2      (pready[2]),
        .pready3      (pready[3]),
        .pready4      (pready[4]),
        .pready5      (pready[5]),
        .sel          (slv_num),
        .mux_out_rdata(rdata),
        .mux_out_ready(ready)
    );
endmodule

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

        //if (addr[31:12] == 20'h1000_0) begin
        //    slv_num = 3'd0;
        //end else if (addr[31:16] == 20'h2000) begin
        //    if (addr[15:12] == 4'b0000) begin
        //        slv_num = 3'd1;
        //    end else if (addr[15:12] == 4'b0001) begin
        //        slv_num = 3'd2;
        //    end else if (addr[15:12] == 4'b0010) begin
        //        slv_num = 3'd3;
        //    end else if (addr[15:12] == 4'b0011) begin
        //        slv_num = 3'd4;
        //    end else if (addr[15:12] == 4'b0100) begin
        //        slv_num = 3'd5;
        //    end
        //end

    end
endmodule

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




//input               pslverr0,
//input        [31:0] prdata0,
//input               pready0,
//input               pslverr1,
//input        [31:0] prdata1,
//input               pready1,
//input               pslverr2,
//input        [31:0] prdata2,
//input               pready2,
//input               pslverr3,
//input        [31:0] prdata3,
//input               pready3,
//input               pslverr4,
//input        [31:0] prdata4,
//input               pready4,


//output logic        psel0,     //ROM
//output logic        psel1,     //RAM
//output logic        psel2,     //GPO
//output logic        psel3,     //GPI
//output logic        psel4,     //GPIO
//output logic        psel5,     //FND
//output logic        psel6      //UART





// if (addr[31:12] == 20'h0000_0) begin
//     slv_num = 3'd0;
//     psel0   = 1'b1;
// end else if (addr[31:12] == 20'h1000_0) begin
//     slv_num = 3'd1;
//     psel1   = 1'b1;
// end else if (addr[31:16] == 20'h2000) begin
//     if (addr[15:12] == 4'b0000) begin
//         slv_num = 3'd2;
//         psel2   = 1'b1;
//     end else if (addr[15:12] == 4'b0001) begin
//         slv_num = 3'd3;
//         psel3   = 1'b1;
//     end else if (addr[15:12] == 4'b0010) begin
//         slv_num = 3'd4;
//         psel4   = 1'b1;
//     end else if (addr[15:12] == 4'b0011) begin
//         slv_num = 3'd5;
//         psel5   = 1'b1;
//     end else if (addr[15:12] == 4'b0100) begin
//         slv_num = 3'd6;
//         psel6   = 1'b1;
//     end
//
// end




//penable = 1'b1;
//slverr  = pslverr;
//if (addr[31:12] == 20'h0000_0) begin
//    psel0 = 1'b1;
//end else if (addr[31:12] == 20'h1000_0) begin
//    psel1 = 1'b1;
//end else if (addr[31:16] == 20'h2000) begin
//    if (addr[15:12] == 4'b0000) psel2 = 1'b1;
//    else if (addr[15:12] == 4'b0001) psel3 = 1'b1;
//    else if (addr[15:12] == 4'b0010) psel4 = 1'b1;
//    else if (addr[15:12] == 4'b0011) psel5 = 1'b1;
//    else if (addr[15:12] == 4'b0100) psel6 = 1'b1;
//end



//if (addr[31:12] == 20'h1000_0) begin
//    psel[0] = 1'b1;
//end else if (addr[31:16] == 20'h2000) begin
//    if (addr[15:12] == 4'b0000) psel[1] = 1'b1;
//    else if (addr[15:12] == 4'b0001) psel[2] = 1'b1;
//    else if (addr[15:12] == 4'b0010) psel[3] = 1'b1;
//    else if (addr[15:12] == 4'b0011) psel[4] = 1'b1;
//    else if (addr[15:12] == 4'b0100) psel[5] = 1'b1;
//end
