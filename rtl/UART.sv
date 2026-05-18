`timescale 1ns / 1ps

module UART (
    input               pclk,
    input               prst,
    input        [31:0] paddr,
    input        [31:0] pwdata,   //CPU -> UART TX -> PC
    input               pwrite,
    input               penable,
    input               psel,
    input               uart_rx,
    output logic        uart_tx,
    output logic [31:0] prdata,   //PC -> UART RX -> CPU -> FND(pwdata)
    output logic        pready
);

    localparam [11:0] uart_ctl_addr = 12'h000;
    localparam [11:0] uart_baud_addr = 12'h004;
    localparam [11:0] uart_status_addr = 12'h008;
    localparam [11:0] uart_txdata_addr = 12'h00c;
    localparam [11:0] uart_rxdata_addr = 12'h010;

    //레지스터 
    logic tx_start_reg, rx_done_flag;
    logic [1:0] baud_reg;
    logic [7:0] tx_data_reg, rx_data_reg;

    //내부 신호
    logic tx_busy, tx_done;
    logic [7:0] rx_data_wire;


//    logic [7:0] tx_data_reg, baud_reg, ctl_reg, status_reg, rx_data_reg, rx_data_wire;
//    logic tx_start, tx_busy, rx_done, b_tick;
//    logic [7:0] rx_data;

    assign pready = (penable & psel) ? 1'b1 : 1'b0;

    assign prdata = (paddr[11:0] == uart_ctl_addr) ? {31'd0, tx_start_reg} : 
                    (paddr[11:0] == uart_baud_addr) ? {30'd0, baud_reg} : 
                    (paddr[11:0] == uart_status_addr) ? {rx_done_flag, 30'd0, tx_busy} : 
                    (paddr[11:0] == uart_txdata_addr) ? {24'd0, tx_data_reg} : 
                    (paddr[11:0] == uart_rxdata_addr) ? {24'd0, rx_data_reg} : 32'hxxxx_xxxx;


    always_ff @(posedge pclk, posedge prst) begin
        if (prst) begin
            tx_data_reg <= 0;
            rx_data_reg <= 0;
            tx_start_reg <= 0;
            rx_done_flag  <= 0;
            baud_reg    <= 0;
        end else begin
            //rx 데이터 캡쳐 및 플래그 세팅
            if(rx_done) begin
                rx_data_reg <= rx_data_wire;
                rx_done_flag <= 1'b1;
            end

            //CPU가 rx 데이터 읽어가면 플래그 내림
            if(psel && penable && !pwrite && (paddr[11:0] == uart_rxdata_addr)) begin
                rx_done_flag <= 1'b0;
            end

            //apb write 동작
            if(pready && pwrite) begin
                case(paddr[11:0]) 
                    uart_ctl_addr: tx_start_reg <= pwdata[0];   //start 신호 받아옴
                    uart_baud_addr: baud_reg <= pwdata[1:0];   //baudrate 결정
                    uart_txdata_addr: tx_data_reg <= pwdata[7:0];
                endcase
            end else begin
                //tx_start 1클럭만 유지되도록
                tx_start_reg <= 1'b0;
            end
        end
    end

    uart_tx U_UART_TX (
        .clk     (pclk),
        .rst     (prst),
        .tx_start(tx_start_reg),
        .b_tick  (b_tick),
        .tx_data (tx_data_reg),
        .tx_busy (tx_busy),
        .tx_done (),
        .uart_tx (uart_tx)
    );

    uart_rx U_UART_RX (
        .clk    (pclk),
        .rst    (prst),
        .rx     (uart_rx),
        .b_tick (b_tick),
        .rx_data(rx_data_wire), //그대로 내보내는 거 아니고 내부 wire로 연결
        .rx_done(rx_done)
    );

    baud_tick U_BAUD_TICK_GEN (
        .clk     (pclk),
        .rst     (prst),
        .baud_sel(baud_reg),
        .b_tick  (b_tick)
    );

endmodule



module uart_rx (
    input        clk,
    input        rst,
    input        rx,       //in Data
    input        b_tick,
    output [7:0] rx_data,  // out data
    output       rx_done
);

    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg done_reg, done_next;
    reg [7:0] buf_reg, buf_next;

    assign rx_data = buf_reg;
    assign rx_done = done_reg;

    //State Register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= 2'd0;
            b_tick_cnt_reg <= 5'd0;
            bit_cnt_reg    <= 3'd0;
            done_reg       <= 1'b0;
            buf_reg        <= 8'd0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end

    //Next, Output CL
    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;

        case (c_state)
            IDLE: begin
                bit_cnt_next    = 3'd0;
                done_next       = 1'b0;
                b_tick_cnt_next = 5'b0;

                if (b_tick & !rx) begin  //b_tick == 1 && rx == 0
                    buf_next = 8'd0;
                    n_state  = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        b_tick_cnt_next = 5'd0;
                        // bit_cnt_next = bit_cnt_reg + 1;  
                        buf_next[7]     = rx;
                        n_state         = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        b_tick_cnt_next = 5'd0;
                        buf_next        = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state   = IDLE;
                        done_next = 1'b1;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end


        endcase

    end

endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,
    input  [7:0] tx_data,   //in data
    output       tx_busy,
    output       tx_done,
    output       uart_tx    //Output Data
);

    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [3:0] c_state, n_state;
    reg tx_reg, tx_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg busy_reg, busy_next;
    reg done_reg, done_next;
    reg [7:0] data_in_buf_reg, data_in_buf_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;

    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    //State Register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 0;
            busy_reg        <= 0;
            done_reg        <= 0;
            data_in_buf_reg <= 8'h00;
            b_tick_cnt_reg  <= 0;
        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            busy_reg        <= busy_next;
            done_reg        <= done_next;
            data_in_buf_reg <= data_in_buf_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
        end
    end

    //Next state, Output CL
    always @(*) begin
        n_state = c_state;
        tx_next = tx_reg;
        bit_cnt_next = bit_cnt_reg;
        busy_next = busy_reg;
        done_next = done_reg;
        data_in_buf_next = data_in_buf_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        case (c_state)
            IDLE: begin
                tx_next         = 1;
                bit_cnt_next    = 0;
                b_tick_cnt_next = 0;
                busy_next       = 0;
                done_next       = 0;
                if (tx_start) begin
                    n_state = START;
                    busy_next = 1;
                    data_in_buf_next = tx_data;
                end
            end
            START: begin
                tx_next = 0;  //to start uart frame of start bit
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state = DATA;
                        b_tick_cnt_next = 4'h0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_in_buf_reg[0];  //Shift Register
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 4'h0;
                            n_state         = STOP;
                        end else begin
                            b_tick_cnt_next  = 4'h0;
                            bit_cnt_next     = bit_cnt_reg + 1;
                            data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                            n_state          = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 4'h0;
                        n_state         = IDLE;
                        busy_next       = 0;
                        done_next       = 1;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

module baud_tick (
    input              clk,
    input              rst,
    input        [1:0] baud_sel,
    output logic       b_tick
);

    //localparam BAUD_9600 = 9600 * 16;
    localparam F_COUNT_9600 = 100_000_000 / (9600 * 16);
    localparam F_COUNT_19200 = 100_000_000 / (19200 * 16);
    localparam F_COUNT_115200 = 100_000_000 / (115200 * 16);

    logic [$clog2(F_COUNT_115200) -1 : 0] counter_reg;
    logic [$clog2(F_COUNT_115200) -1 : 0] baud_count;

    assign baud_count = (baud_sel == 2'b00) ? F_COUNT_9600 : (baud_sel == 2'b01) ? F_COUNT_19200 : (baud_sel == 2'b10) ? F_COUNT_115200 : 0;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            b_tick      <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;

            if (counter_reg == baud_count - 1) begin
                b_tick      <= 1'b1;
                counter_reg <= 0;
            end else begin
                b_tick <= 1'b0;
            end
        end
    end

endmodule
