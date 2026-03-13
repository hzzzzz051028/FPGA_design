`include "define.v"

module EX(
    input wire clk,
    input wire rst,

    input wire [5:0] op,
    input wire [5:0] func,
    input wire [4:0] rs,
    input wire [4:0] shamt,

    input wire [31:0] regaData,
    input wire [31:0] regbData,
    input wire [31:0] imm,
    input wire LLbit,

    output reg [31:0] regcData,
    output reg [31:0] Hi,
    output reg [31:0] Lo,

    output reg memWrite,
    output reg memCe,

    output reg exception,
    output reg eret,
    output reg [4:0] excepttype,

    output reg cp0_we,
    output reg [4:0] cp0_waddr,
    output reg [31:0] cp0_wdata,
    output reg [4:0] cp0_raddr
);

reg [63:0] mulres;
wire [31:0] logicImm = {16'b0, imm[15:0]};

always @(*) begin

    regcData   = 32'b0;
    memWrite   = 0;
    memCe      = 0;
    exception  = 0;
    eret       = 0;
    excepttype = 0;

    cp0_we     = 0;
    cp0_waddr  = 0;
    cp0_wdata  = 0;
    cp0_raddr  = 0;

    // ================= R 型 =================
    if(op == `Inst_r) begin
        case(func)
            `Inst_add: begin
                regcData = regaData + regbData;
                // 溢出检测
                if((~regaData[31] & ~regbData[31] & regcData[31]) |
                   (regaData[31] & regbData[31] & ~regcData[31]))
                    exception = 1;
            end
            `Inst_sub: begin
                regcData = regaData - regbData;
                if((~regaData[31] & regbData[31] & regcData[31]) |
                   (regaData[31] & ~regbData[31] & ~regcData[31]))
                    exception = 1;
            end
            `Inst_and: regcData = regaData & regbData;
            `Inst_or : regcData = regaData | regbData;
            `Inst_xor: regcData = regaData ^ regbData;
            `Inst_slt: regcData = ($signed(regaData) < $signed(regbData)) ? 1 : 0;

            `Inst_sll: regcData = regbData << shamt;
            `Inst_srl: regcData = regbData >> shamt;
            `Inst_sra: regcData = $signed(regbData) >>> shamt;

            `Inst_mult: mulres = $signed(regaData) * $signed(regbData);
            `Inst_multu: mulres = regaData * regbData;

            `Inst_div: begin
                Hi = $signed(regaData) % $signed(regbData);
                Lo = $signed(regaData) / $signed(regbData);
            end

            `Inst_divu: begin
                Hi = regaData % regbData;
                Lo = regaData / regbData;
            end

            `Inst_mfhi: regcData = Hi;
            `Inst_mflo: regcData = Lo;
            `Inst_mthi: Hi = regaData;
            `Inst_mtlo: Lo = regaData;

            `Inst_syscall: begin
                exception = 1;
                excepttype = 5'b01000;
            end
        endcase
    end

    // ================= I 型 =================
    case(op)
        `Inst_addi: regcData = regaData + imm;
        `Inst_andi: regcData = regaData & logicImm;
        `Inst_ori : regcData = regaData | logicImm;
        `Inst_xori: regcData = regaData ^ logicImm;
        `Inst_lui : regcData = {imm[15:0],16'b0};

        `Inst_lw: begin
            memCe = 1;
            regcData = regaData + imm;
        end
        `Inst_ll: begin
            memCe = 1;
            regcData = regaData + imm;
        end
        `Inst_sw: begin
            memCe = 1;
            memWrite = 1;
            regcData = regaData + imm;
        end
        `Inst_sc: begin
            memCe = 1;
            memWrite = LLbit;
            regcData = regaData + imm;
        end
    endcase

    // ================= COP0 =================
    if(op == `Inst_cop0) begin
        if(rs == `Inst_mfc0) cp0_raddr = regbData[4:0];
        else if(rs == `Inst_mtc0) begin
            cp0_we = 1;
            cp0_waddr = regbData[4:0];
            cp0_wdata = regaData;
        end
        else if(rs == `Inst_eret_rs && func == `Inst_eret_fun) eret = 1;
    end

end

    // ================= HI/LO 寄存器更新 =================
    always @(posedge clk) begin
        if(rst) begin
            Hi <= 0;
            Lo <= 0;
        end
        else if(op == `Inst_r) begin
            case(func)
                `Inst_mult, `Inst_multu: begin
                    Hi <= mulres[63:32];
                    Lo <= mulres[31:0];
                end
                `Inst_div, `Inst_divu: begin
                    if (regbData != 0) begin
                        Hi <= $signed(regaData) % $signed(regbData);
                        Lo <= $signed(regaData) / $signed(regbData);
                    end
                end
                `Inst_mthi: Hi <= regaData;
                `Inst_mtlo: Lo <= regaData;
            endcase
        end
    end

endmodule