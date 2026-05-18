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
    logic pwrite_next;
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


