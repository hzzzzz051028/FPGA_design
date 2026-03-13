`include "define.v"

module InstMem(
    input wire ce,
    input wire clk,
    input wire [31:0] addr,
    input wire [31:0] writeData,
    input wire memWrite,      
    output reg [31:0] data,  
    output reg [31:0] memOut   
);

reg [31:0] instmem [1023:0];
reg [31:0] datamem [1023:0];
integer i;

always @(posedge clk) begin
    if (ce) begin
        data <= instmem[addr[11:2]]; // 输出指令

        if (memWrite) begin
            datamem[addr[11:2]] <= writeData; // sw写内存
            memOut <= writeData;              // memOut显示写入的数据
        end else begin
            memOut <= datamem[addr[11:2]];   // lw时显示读出的数据
        end
    end else begin
        data <= 32'b0;
        memOut <= 32'b0;
    end
end

initial begin
    for(i = 0; i < 1024; i = i + 1) begin
        instmem[i] = 32'h00000000;
        datamem[i] = 32'h00000000;
    end

    // 20 条基本整数指令 + 12 条扩展整数指令
    // 通过顺序流、分支流、HI/LO 运算与寄存器跳转，完整覆盖课程设计要求。
    instmem[0]  = 32'h20010030; // addi $1,$0,48     -> jr 目标地址 0x30
    instmem[1]  = 32'h2002000D; // addi $2,$0,13
    instmem[2]  = 32'h00221820; // add  $3,$1,$2
    instmem[3]  = 32'h00222022; // sub  $4,$1,$2
    instmem[4]  = 32'h00222824; // and  $5,$1,$2
    instmem[5]  = 32'h00223025; // or   $6,$1,$2
    instmem[6]  = 32'h00223826; // xor  $7,$1,$2
    instmem[7]  = 32'h00024040; // sll  $8,$2,1
    instmem[8]  = 32'h00014882; // srl  $9,$1,2
    instmem[9]  = 32'h00015083; // sra  $10,$1,2
    instmem[10] = 32'h00200008; // jr   $1           -> 跳到索引12
    instmem[11] = 32'h00000000; // nop               -> 被 jr 跨过
    instmem[12] = 32'h0041582A; // slt  $11,$2,$1
    instmem[13] = 32'h3C0C00F0; // lui  $12,16'h00F0
    instmem[14] = 32'h358E00A5; // ori  $14,$12,16'h00A5
    instmem[15] = 32'h31CDF0F0; // andi $13,$14,16'hF0F0
    instmem[16] = 32'h39CF00FF; // xori $15,$14,16'h00FF
    instmem[17] = 32'h20110024; // addi $17,$0,36
    instmem[18] = 32'hAE2D0008; // sw   $13,8($17)
    instmem[19] = 32'h8E320008; // lw   $18,8($17)
    instmem[20] = 32'h11B20001; // beq  $13,$18,1    -> 跳到索引22
    instmem[21] = 32'h00000000; // nop               -> 被 beq 跨过
    instmem[22] = 32'h15F20001; // bne  $15,$18,1    -> 跳到索引24
    instmem[23] = 32'h00000000; // nop               -> 被 bne 跨过
    instmem[24] = 32'h2016FFFB; // addi $22,$0,-5
    instmem[25] = 32'h06C00001; // bltz $22,1        -> 跳到索引27
    instmem[26] = 32'h00000000; // nop               -> 被 bltz 跨过
    instmem[27] = 32'h20170007; // addi $23,$0,7
    instmem[28] = 32'h1EE00001; // bgtz $23,1        -> 跳到索引30
    instmem[29] = 32'h00000000; // nop               -> 被 bgtz 跨过
    instmem[30] = 32'h00570018; // mult $2,$23
    instmem[31] = 32'h0000C012; // mflo $24
    instmem[32] = 32'h0000C810; // mfhi $25
    instmem[33] = 32'h00220019; // multu $1,$2
    instmem[34] = 32'h0000D012; // mflo $26
    instmem[35] = 32'h0022001A; // div  $1,$2
    instmem[36] = 32'h0000D812; // mflo $27
    instmem[37] = 32'h0000E010; // mfhi $28
    instmem[38] = 32'h0037001B; // divu $1,$23
    instmem[39] = 32'h0000E812; // mflo $29
    instmem[40] = 32'h0000F010; // mfhi $30
    instmem[41] = 32'h01E00011; // mthi $15
    instmem[42] = 32'h0000A010; // mfhi $20
    instmem[43] = 32'h01A00013; // mtlo $13
    instmem[44] = 32'h0000A812; // mflo $21
    instmem[45] = 32'h0800002F; // j    0x2F         -> 跳到索引47
    instmem[46] = 32'h00000000; // nop               -> 被 j 跨过
    instmem[47] = 32'h0C000032; // jal  0x32         -> 跳到索引50
    instmem[48] = 32'h00000000; // nop               -> 被 jal 跨过
    instmem[49] = 32'h00000000; // nop               -> 被 jal 跨过
    instmem[50] = 32'h201300D8; // addi $19,$0,216   -> jalr 目标地址 0xD8
    instmem[51] = 32'h02608009; // jalr $16,$19
    instmem[52] = 32'h00000000; // nop               -> 被 jalr 跨过
    instmem[53] = 32'h00000000; // nop               -> 被 jalr 跨过
    instmem[54] = 32'h20160055; // addi $22,$0,85    -> 程序结束标志
end

endmodule