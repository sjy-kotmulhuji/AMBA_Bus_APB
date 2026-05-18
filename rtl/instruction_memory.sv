`timescale 1ns / 1ps

module instruction_memory (
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    logic [31:0] rom[0:255];


    initial begin
        $readmemh("apb_final.mem", rom);
        //rom[0] = 32'h004182b3;  //R-Type ADD x5, x3, x4    register_file[5] = register_file[3] + register_file[4] = 3 + 4 = 7  
        //rom[1] = 32'h00812123;  //S-Type SW x2, 2(x8),  SW x2, x8, 2
        //rom[2] = 32'h00212383;  //LW x7, x2, 2
        //rom[3] = 32'h00838463;  //BEQ x7, x8, 8증가
        //rom[4] = 32'h004182b3;  //ADD x5, x3, x4    register_file[5] = register_file[3] + register_file[4] = 3 + 4 = 7  
        //rom[5] = 32'h0000d2b7;  //LUI imm = 53248, rd = x5
        //rom[6] = 32'h0000a317;  //AUIPC imm = 40960, rd = x6
        //rom[7] = 32'h00668223;  //SB imm = 4, rs1 = x13, rs2 = x6
        //rom[8] = 32'h00649223;  //SH imm = 4, rs1 = x9, rs2 = x6
        //rom[5] = 32'h0000d2b7;  //LUI imm = 53248, rd = x5
        //rom[6] = 32'h0000a317;  //AUIPC imm = 40960, rd = x6
        //rom[7] = 32'h020003ef;  //JAL imm = 16, rd = x7

        //JALR
        //rom[0] = 32'h02080267;  //JALR imm = 32, rs1 = 16, rd = x4

        //R-Type
        //rom[0] = 32'h004182b3;  //ADD x5, x3, x4    register_file[5] = register_file[3] + register_file[4] = 3 + 4 = 7  
        //rom[1] = 32'h404182b3;  //SUB x5, x3, x4
        //rom[2] = 32'h004192b3;  //SLL x5, x3, x4
        //rom[3] = 32'h004fa2b3;  //SLT x5, x31, x4
        //rom[4] = 32'h004fb2b3;  //SLTU x5, x31, x4
        //rom[5] = 32'h0041c2b3;  //XOR x5, x3, x4
        //rom[6] = 32'h004fd2b3;  //SRL x5, x31, x4
        //rom[7] = 32'h404fd2b3;  //SRA x5, x31, x4
        //rom[8] = 32'h0041e2b3;  //OR x5, x3, x4
        //rom[9] = 32'h0041f2b3;  //AND x5, x3, x4
        //rom[10] = 32'h03840267;  //JALR imm = 56, rs1 = x8, rd = x4

        //S-Type
        //rom[0] = 32'h01f40223;  //sb x31, 4(x8)
        //rom[1] = 32'h01f402a3;  //sb x31, 5(x8)
        //rom[2] = 32'h01f40323;  //sb x31, 6(x8)
        //rom[3] = 32'h01f403a3;  //sb x31, 7(x8)
        //rom[4] = 32'h01f61223;  //sh x31, 4(x12)
        //rom[5] = 32'h01f61323;  //sh x31, 6(x12)
        //rom[6] = 32'h01f82223;  //sw x31, 4(x16)

        //L-Type
        //rom[0] = 32'h01f22223;  //M[2]에 x31 값 저장  sw x31, 4(x4) 
        //rom[1] = 32'h00420403;  //lb x8, 4(x4)
        //rom[2] = 32'h00520403;  //lb x8, 5(x4)
        //rom[3] = 32'h00620403;  //lb x8, 6(x4)
        //rom[4] = 32'h00720403;  //lb x8, 7(x4)
        //rom[5] = 32'h00421403;  //lh x8, 4(x4)
        //rom[6] = 32'h00621403;  //lh x8, 6(x4)
        //rom[7] = 32'h00422403;  //lw x8, 4(x4)


        //B-Type
        //rom[0] = 32'h00b50463;  //BEQ x10, x11, 8           f
        //rom[1] = 32'h00b51663;   //BNE x10, x11, 12         t
        //rom[4] = 32'h01f54863;   //BLT x10, x31, 16         f
        //rom[5] = 32'h01f55863;   //BGE x10, x31, 16         t
        //rom[9] = 32'h01f56a63;   //BLTU x10, x31, 20       t
        //rom[14] = 32'h01f57a63;   //BGEU x10, x31, 20       f
    end

    assign instr_data = rom[instr_addr[31:2]];   //주소 4씩 증가될 때 1 증가하는 걸로 인식(하위 2비트 짤라버림)
                                                 //word addressing -> byte addressing
endmodule

