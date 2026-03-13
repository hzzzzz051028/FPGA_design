`include "define.v"

module IF(
    input wire clk,
    input wire rst,

    input wire exception,
    input wire eret,
    input wire [31:0] epc,

    input wire [31:0] jAddr,
    input wire jCe,

    output wire romCe,
    output reg [31:0] pc
);

// =======================
// ROM 使能
// =======================
assign romCe = (rst == `RstEnable) ? `RomDisable : `RomEnable;


// =======================
// PC 更新逻辑
// =======================
always @(posedge clk) begin
    if(rst == `RstEnable)
        pc <= `Zero;
    else if(eret)
        pc <= epc;
    // else if(exception)
    //    pc <= 32'h80000180;   // 屏蔽掉跳转，让它能跑到 eret
    else if(jCe == `Valid)
        pc <= jAddr;
    else
        pc <= pc + 4;
end

endmodule