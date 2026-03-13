`include "define.v"

module MIPS(
    input wire clk,
    input wire rst,

    output wire [31:0] regaData_out,
    output wire jalr_ctrl_out
);

wire [31:0] pc;
wire [31:0] instruction;
wire [31:0] regaData;    
wire [31:0] regbData;

// 指令字段解析 (提前到这里)
wire [5:0] op    = instruction[31:26];
wire [5:0] func  = instruction[5:0];
wire [4:0] rs    = instruction[25:21];
wire [4:0] rt    = instruction[20:16];
wire [4:0] rd    = instruction[15:11];
wire [4:0] shamt = instruction[10:6];

// =====================================================
// IF 控制逻辑
// =====================================================
wire romCe;
wire exception;
wire eret;
wire [31:0] epc;

// =====================================================
// LLbit 寄存器定义 (必须在使用前定义)
// =====================================================
reg LLbit;
always @(posedge clk) begin
    if(rst)
        LLbit <= 1'b0;
    else if(op == `Inst_ll)
        LLbit <= 1'b1;
    else if(op == `Inst_sc || exception)
        LLbit <= 1'b0;
end

wire is_jalr = (op == `Inst_r && func == `Inst_jalr);
wire is_jal  = (op == `Inst_jal);
wire is_j    = (op == `Inst_j);
wire is_jr   = (op == `Inst_r && func == `Inst_jr);
wire is_beq  = (op == `Inst_beq);
wire is_bne  = (op == `Inst_bne);
wire is_bltz = (op == `Inst_bltz);
wire is_bgtz = (op == `Inst_bgtz);

wire beq_taken  = is_beq  && (regaData == regbData);
wire bne_taken  = is_bne  && (regaData != regbData);
wire bltz_taken = is_bltz && ($signed(regaData) < 0);
wire bgtz_taken = is_bgtz && ($signed(regaData) > 0);
wire [31:0] branchOffset = {{14{instruction[15]}}, instruction[15:0], 2'b00};
wire [31:0] branchAddr = pc + branchOffset;

wire jCe = is_jalr || is_jr || is_jal || is_j || beq_taken || bne_taken || bltz_taken || bgtz_taken;
wire [31:0] jAddr = (is_j || is_jal) ? {pc[31:28], instruction[25:0], 2'b00} :
                    (beq_taken || bne_taken || bltz_taken || bgtz_taken) ? branchAddr :
                    regaData;

IF if0(
    .clk(clk),
    .rst(rst),
    .exception(exception),
    .eret(eret),
    .epc(epc),
    .jAddr(jAddr),
    .jCe(jCe),
    .romCe(romCe),
    .pc(pc)
);

// =====================================================
// 指令存储器
// =====================================================
InstMem im(
    .ce(romCe),
    .clk(clk),
    .addr(pc),
    .writeData(32'b0),
    .memWrite(1'b0),
    .data(instruction),
    .memOut()
);

// =====================================================
// EX 与存储器 
// =====================================================
wire [31:0] exOut;
wire [31:0] memOut;
wire memWrite;
wire memCe;
wire [4:0] excepttype;
wire [31:0] imm = {{16{instruction[15]}}, instruction[15:0]};

wire [31:0] Hi, Lo;
wire cp0_we;
wire [4:0] cp0_waddr, cp0_raddr;
wire [31:0] cp0_wdata;

EX ex0(
    .clk(clk),
    .rst(rst),
    .op(op),
    .func(func),
    .rs(rs),
    .regaData(regaData),
    .regbData(regbData),
    .regcData(exOut),
    .Hi(Hi),
    .Lo(Lo),
    .memWrite(memWrite),
    .memCe(memCe),
    .exception(exception),
    .eret(eret),
    .excepttype(excepttype),
    .cp0_we(cp0_we),
    .cp0_waddr(cp0_waddr),
    .cp0_wdata(cp0_wdata),
    .cp0_raddr(cp0_raddr),
    .imm(imm),
    .shamt(shamt),
    .LLbit(LLbit)
);

DataMem dm(
    .clk(clk),
    .ce(memCe),
    .we(memWrite),
    .addr(exOut),
    .dataIn(regbData),
    .dataOut(memOut)
);

// =====================================================
// 写回控制
// =====================================================
wire [31:0] writeData;
wire [4:0]  writeReg;
wire regWrite;

// 写回寄存器选择
assign writeReg =
    (is_jal)           ? 5'd31 :            
    (is_jalr)          ? rd    :            
    (op == `Inst_r)    ? rd    :            
    (op == `Inst_lw ||
     op == `Inst_ll ||
     op == `Inst_sc ||
     op == `Inst_addi || 
     op == `Inst_andi || 
     op == `Inst_ori  || 
     op == `Inst_xori || 
     op == `Inst_lui) ? rt : 
                         5'b00000;

// 写回数据选择
assign writeData = 
    (is_jal || is_jalr) ? pc :   
    (op == `Inst_sc)    ? {31'b0, LLbit} : // sc 指令写回 LLbit 状态
    (op == `Inst_lw || op == `Inst_ll) ? memOut :         
                          exOut;          

// 寄存器写使能
wire inst_writes_reg =
    (is_jal || is_jalr) ||                  
    (op == `Inst_r && func != `Inst_jr) ||  
    (op == `Inst_lw)   ||
    (op == `Inst_ll)   ||
    (op == `Inst_sc)   ||
    (op == `Inst_addi) || 
    (op == `Inst_andi) ||
    (op == `Inst_ori)  || 
    (op == `Inst_xori) || 
    (op == `Inst_lui);

assign regWrite = inst_writes_reg && (writeReg != 5'd0);

    // =====================================================
    // 寄存器堆
    // =====================================================
RegFile rf(
    .clk(clk),
    .rst(rst),
    .we(regWrite),
    .waddr(writeReg),
    .wdata(writeData),
    .regaAddr(rs),
    .regbAddr(rt),
    .regaData(regaData),
    .regbData(regbData)
);

assign regaData_out = regaData;
assign jalr_ctrl_out = (op == `Inst_r && func == `Inst_jalr);

// =====================================================
// CP0
// =====================================================
wire [31:0] cp0_rdata;
wire [31:0] status;
wire [31:0] cause;

cp0 cp0_0(
    .clk(clk),
    .rst(rst),
    .we_i(cp0_we),
    .waddr_i(cp0_waddr),
    .data_i(cp0_wdata),
    .raddr_i(cp0_raddr),
    .data_o(cp0_rdata),
    .exception_i(exception),
    .current_pc_i(pc),
    .excepttype_i(excepttype),
    .eret_i(eret),
    .epc_o(epc),
    .status_o(status),
    .cause_o(cause)
);

endmodule