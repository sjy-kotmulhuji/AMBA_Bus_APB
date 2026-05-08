//`define SIMULATION 

`define R_TYPE 7'b011_0011
`define B_TYPE 7'b110_0011
`define S_TYPE 7'b010_0011
`define JL_TYPE 7'b110_0111
`define IL_TYPE 7'b000_0011
`define I_TYPE 7'b001_0011
`define UL_TYPE 7'b011_0111     
`define U_TYPE 7'b001_0111
`define J_TYPE 7'b110_1111


//R-type instruction
`define ADD 4'b0000 
`define SUB 4'b1000 
`define SLL 4'b0001 
`define SLT 4'b0010
`define SLTU 4'b0011  
`define XOR 4'b0100 
`define SRL 4'b0101 
`define SRA 4'b1101
`define OR 4'b0110
`define AND 4'b0111 

//B-type instruction    하위 3비트만 사용
`define BEQ 4'b0_000
`define BNE 4'b0_001
`define BLT 4'b0_100
`define BGE 4'b0_101
`define BLTU 4'b0_110
`define BGEU 4'b0_111
