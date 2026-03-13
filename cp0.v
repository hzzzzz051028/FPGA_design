`include "define.v"

module cp0(
    input wire clk,
    input wire rst,

    input wire we_i,
    input wire [4:0] waddr_i,
    input wire [31:0] data_i,

    input wire [4:0] raddr_i,
    output reg [31:0] data_o,

    input wire exception_i,
    input wire [31:0] current_pc_i,
    input wire [4:0] excepttype_i,

    input wire eret_i,

    output reg [31:0] epc_o,
    output reg [31:0] status_o,
    output reg [31:0] cause_o
);

// CP0 寄存器编号
localparam CP0_STATUS = 5'd12;
localparam CP0_CAUSE  = 5'd13;
localparam CP0_EPC    = 5'd14;

// =============================
// 读
// =============================
always @(*) begin
    case(raddr_i)
        CP0_STATUS: data_o = status_o;
        CP0_CAUSE : data_o = cause_o;
        CP0_EPC   : data_o = epc_o;
        default   : data_o = 32'b0;
    endcase
end

// =============================
// 写 + 异常处理
// =============================
always @(posedge clk) begin
    if(rst == `RstEnable) begin
        status_o <= 32'b0;
        cause_o  <= 32'b0;
        epc_o    <= 32'b0;
    end
    else begin

        // MTC0 写
        if(we_i) begin
            case(waddr_i)
                CP0_STATUS: status_o <= data_i;
                CP0_CAUSE : cause_o  <= data_i;
                CP0_EPC   : epc_o    <= data_i;
            endcase
        end

        // 异常发生
        if(exception_i) begin
            epc_o <= current_pc_i;
            cause_o[6:2] <= excepttype_i;
            status_o[1] <= 1'b1; // EXL 位置1
        end

        // eret
        if(eret_i) begin
            status_o[1] <= 1'b0; // 清除 EXL
        end

    end
end

endmodule