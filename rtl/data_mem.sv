`timescale 1ns / 1ps

module data_mem (
    input               clk,
    input               rst,
    input               dwe,
    input        [ 2:0] i_funct3,
    input        [31:0] daddr,     //write address, read address
    input        [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] dmem[0:256];
    logic [3:0] byte_en;

    byte_enable U_BE (
        .addr   (daddr[1:0]),
        .byte_en(byte_en)
    );

    always_ff @(posedge clk) begin
        if (!rst & dwe) begin
            if (i_funct3 == 3'b010) dmem[daddr[31:2]] <= dwdata;  //SW
            else if (i_funct3 == 3'b000) begin  //SB
                if (byte_en == 4'b0001)
                    dmem[daddr[31:2]] <= {dmem[daddr[31:2]][31:8], dwdata[7:0]};
                else if (byte_en == 4'b0010)
                    dmem[daddr[31:2]] <= {
                        dmem[daddr[31:2]][31:16],
                        dwdata[7:0],
                        dmem[daddr[31:2]][7:0]
                    };
                else if (byte_en == 4'b0100)
                    dmem[daddr[31:2]] <= {
                        dmem[daddr[31:2]][31:24],
                        dwdata[7:0],
                        dmem[daddr[31:2]][15:0]
                    };
                else if (byte_en == 4'b1000)
                    dmem[daddr[31:2]] <= {dwdata[7:0], dmem[daddr[31:2]][23:0]};
            end else if (i_funct3 == 3'b001) begin  //SH
                if (byte_en == 4'b0001)
                    dmem[daddr[31:2]] <= {
                        dmem[daddr[31:2]][31:16], dwdata[15:0]
                    };
                else if (byte_en == 4'b0100)
                    dmem[daddr[31:2]] <= {
                        dwdata[15:0], dmem[daddr[31:2]][15:0]
                    };
            end
        end
    end



    always_comb begin
        if (i_funct3 == 3'b010) drdata = dmem[daddr[31:2]];  //LW
        else if (i_funct3 == 3'b000) begin  //LB
            if (byte_en == 4'b0001)
                drdata = {{24{dmem[daddr[31:2]][7]}}, dmem[daddr[31:2]][7:0]};
            else if (byte_en == 4'b0010)
                drdata = {{24{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:8]};
            else if (byte_en == 4'b0100)
                drdata = {
                    {24{dmem[daddr[31:2]][23]}}, dmem[daddr[31:2]][23:16]
                };
            else if (byte_en == 4'b1000)
                drdata = {
                    {24{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:24]
                };
        end else if (i_funct3 == 3'b001) begin  //LH
            if (byte_en == 4'b0001)
                drdata = {{16{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:0]};
            else if (byte_en == 4'b0100)
                drdata = {
                    {16{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:16]
                };
        end else if (i_funct3 == 3'b100) begin  //LBU
            if (byte_en == 4'b0001) drdata = {24'b0, dmem[daddr[31:2]][7:0]};
            else if (byte_en == 4'b0010)
                drdata = {24'b0, dmem[daddr[31:2]][15:8]};
            else if (byte_en == 4'b0100)
                drdata = {24'b0, dmem[daddr[31:2]][23:16]};
            else if (byte_en == 4'b1000)
                drdata = {24'b0, dmem[daddr[31:2]][31:24]};
        end else if (i_funct3 == 3'b101) begin  //LHU
            if (byte_en == 4'b0001) drdata = {16'b0, dmem[daddr[31:2]][15:0]};
            else if (byte_en == 4'b0100)
                drdata = {16'b0, dmem[daddr[31:2]][31:16]};
        end
    end

endmodule

module byte_enable (
    input [1:0] addr,
    output logic [3:0] byte_en
);
    always_comb begin
        case (addr)
            2'b00:   byte_en = 4'b0001;  //0~7비트
            2'b01:   byte_en = 4'b0010;  //8~15비트
            2'b10:   byte_en = 4'b0100;  //16~23비트
            2'b11:   byte_en = 4'b1000;  //24~31비트
            default: byte_en = 4'b0001;
        endcase
    end

endmodule

//Byte Address
//    logic [7:0] dmem[0:31];
//
//    always_ff @(posedge clk, posedge rst) begin
//        if (rst) begin
//
//        end else begin
//            if (dwe) begin
//                dmem[daddr]   <= dwdata[7:0];   //SW인 경우 주소 8bit씩 쪼개서 넣기
//                dmem[daddr+1] <= dwdata[15:8];
//                dmem[daddr+2] <= dwdata[23:16];
//                dmem[daddr+3] <= dwdata[31:24];
//            end
//        end
//    end
//
//    assign drdata = {
//        dmem[daddr], dmem[daddr+1], dmem[daddr+2], dmem[daddr+3]
//    };
//assign drdata = dmem[daddr[31:2]];  //word align
