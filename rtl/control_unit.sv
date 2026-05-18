`timescale 1ns / 1ps
`include "define.vh"

module control_unit (
    input              clk,
    input              rst,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    input              ready,
    output logic       pc_en,
    output logic       rf_we,
    output logic       branch,
    output logic       jal,
    output logic       jalr,
    output logic       alu_src,
    output logic [3:0] alu_control,
    output logic [2:0] rfwd_src,
    output logic [2:0] o_funct3,
    output logic       dwe,
    output logic       dre
);

    typedef enum {
        FETCH,
        DECODE,
        EXECUTE,
        MEMORY,
        WB
    } state_e;

    state_e c_state, n_state;

    //State Register SL
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    //Next State CL
    always_comb begin
        n_state = c_state;
        case (c_state)
            FETCH: begin
                n_state = DECODE;
            end
            DECODE: begin
                n_state = EXECUTE;
            end
            EXECUTE: begin
                case (opcode)
                    `B_TYPE, `R_TYPE, `I_TYPE, `U_TYPE, `UL_TYPE, `J_TYPE, `JL_TYPE: begin
                        n_state = FETCH;
                    end
                    //`R_TYPE, `I_TYPE, `U_TYPE, `UL_TYPE, `J_TYPE, `JL_TYPE: begin
                    //    n_state = WB;
                    //end
                    `S_TYPE, `IL_TYPE: begin
                        n_state = MEMORY;
                    end
                endcase
            end
            MEMORY: begin
                if (ready) begin
                    case (opcode)
                        `S_TYPE: begin
                            n_state = FETCH;
                        end
                        `IL_TYPE: begin
                            n_state = WB;
                        end
                    endcase
                end
            end

            WB: begin
                //IL Type, Memory 단계에서 처리해도 됨
                n_state = FETCH;

            end
        endcase
    end

    //Output CL
    always_comb begin
        pc_en       = 1'b0;
        rf_we       = 1'b0;
        branch      = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        rfwd_src    = 3'b000;
        o_funct3    = 3'b000;
        dwe         = 1'b0;  //for S Type
        dre         = 1'b0;  //for IL Type
        case (c_state)
            FETCH: begin
                pc_en = 1'b1;
            end
            DECODE: begin

            end
            EXECUTE: begin
                case (opcode)
                    `R_TYPE: begin
                        rf_we = 1'b1;
                        alu_control = {funct7[5], funct3};
                        rfwd_src = 3'b000;
                    end
                    `B_TYPE: begin
                        branch      = 1'b1;
                        alu_control = {1'b0, funct3};
                    end
                    `S_TYPE: begin
                        alu_src     = 1'b1;
                        alu_control = `ADD;
                    end
                    `JL_TYPE: begin  //JALR rd = pc+4, pc = rs1 + imm
                        rf_we    = 1'b1;
                        jal      = 1'b1;
                        jalr     = 1'b1;
                        alu_src  = 1'b1;
                        rfwd_src = 3'b100;
                    end
                    `IL_TYPE: begin
                        alu_src = 1'b1;
                        alu_control = `ADD;
                    end
                    `I_TYPE: begin
                        rf_we   = 1'b1;
                        alu_src = 1'b1;
                        if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
                        else alu_control = {1'b0, funct3};
                        rfwd_src = 3'b000;
                    end
                    `UL_TYPE: begin  //LUI rd = imm
                        rf_we = 1'b1;
                        alu_src = 1'b1;  //don't care
                        rfwd_src = 3'b010;
                    end
                    `U_TYPE: begin  //AUIPC rd = pc + imm
                        rf_we = 1'b1;
                        alu_src = 1'b1;  //don't care
                        rfwd_src = 3'b011;
                    end
                    `J_TYPE: begin  //JAL rd = pc+4, pc += imm
                        rf_we    = 1'b1;
                        jal      = 1'b1;
                        alu_src  = 1'b1;  //don't care
                        rfwd_src = 3'b100;
                    end
                endcase
            end
            MEMORY: begin
                case (opcode)
                    `S_TYPE: begin
                        dwe = 1'b1;
                        o_funct3    = funct3;
                    end
                    `IL_TYPE: begin
                        dwe = 1'b0;
                        dre = 1'b1;  //이거 때문에 명령어 끝까지x
                        o_funct3 = funct3;
                    end
                endcase
            end
            WB: begin
                case (opcode)
                    `IL_TYPE: begin
                        //dre = 1'b1;
                        rf_we = 1'b1;
                        rfwd_src = 3'b001;
                    end
                endcase
            end
        endcase
    end

endmodule