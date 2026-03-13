`include "define.v"

module cpu_top(
    input wire clk,
    input wire rst,

    input wire [31:0] regaData,
    input wire jalr_ctrl
);

// ========================
// PC
// ========================
reg [31:0] pc;
wire [31:0] next_pc;

// ========================
// 异常 / eret / syscall
// ========================
wire exception;
wire eret;

// ========================
// LL/SC
// ========================
wire ll;
wire sc;
reg LLbit;

// ========================
// CP0
// ========================
wire [31:0] epc;
wire [31:0] cp0_data;

// ========================
// 指令解码
// ========================
wire [5:0] opcode;
wire [5:0] funct;
wire [4:0] rs;
wire [4:0] rt;
wire [4:0] rd;

wire regwrite_ctrl;

// ======================== 
// 指令寄存器 / 示例
// ========================
wire [31:0] inst;
wire syscall;

assign opcode = inst[31:26];
assign rs     = inst[25:21];
assign rt     = inst[20:16];
assign rd     = inst[15:11];
assign funct  = inst[5:0];

// ========================
// 控制器
// ========================
control u_control(
    .opcode(opcode),
    .funct(funct),
    .rs(rs),
    .regwrite(regwrite_ctrl),
    .memwrite(),
    .memread(),
    .mfc0(),
    .mtc0(),
    .eret(eret),
    .syscall(syscall),
    .ll(ll),
    .sc(sc),
    .jalr_ctrl(jalr_ctrl)
);

// ========================
// 寄存器文件
// ========================
// 寄存器文件
wire [31:0] regbData;
reg [31:0] wdata;
reg [4:0] waddr;
reg we;

RegFile u_regfile(
    .clk(clk),
    .rst(rst),
    .we(we),
    .waddr(waddr),
    .wdata(wdata),
    .regaAddr(rs),
    .regbAddr(rt),
    .regaData(regaData),
    .regbData(regbData)
);

// 写回逻辑
always @(*) begin                         
    we = regwrite_ctrl && (rd != 0); 
end

// ========================
// CP0
// ========================
cp0 u_cp0(
    .clk(clk),
    .rst(rst),
    .we_i(1'b0),
    .waddr_i(5'b0),
    .data_i(32'b0),
    .raddr_i(5'b0),
    .data_o(cp0_data),
    .exception_i(exception),
    .current_pc_i(pc),
    .excepttype_i(5'b01000),
    .eret_i(eret),
    .epc_o(epc),
    .status_o(),
    .cause_o()
);

// ========================
// LLbit
// ========================
always @(posedge clk) begin
    if(rst)
        LLbit <= 0;
    else if(ll)
        LLbit <= 1;
    else if(sc)
        LLbit <= 0;
end

// ========================
// 异常
// ========================
assign exception = syscall;

// ========================
// PC 更新
// ========================
always @(posedge clk) begin
    if(rst)
        pc <= 0;
    else
        pc <= next_pc;
end

assign next_pc =
        eret        ? epc :
        exception   ? 32'h80000180 :
        jalr_ctrl   ? regaData :
        pc + 4;

endmodule