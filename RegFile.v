`include "define.v"

module RegFile(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata,
    input wire [4:0] regaAddr,
    input wire [4:0] regbAddr,
    output wire [31:0] regaData,
    output wire [31:0] regbData
);

reg [31:0] reg32 [31:0];
integer i;

assign regaData = (regaAddr==0)?0:reg32[regaAddr];
assign regbData = (regbAddr==0)?0:reg32[regbAddr];

always @(posedge clk) begin
    if(rst == `RstEnable) begin
        for(i = 0; i < 32; i = i + 1)
            reg32[i] <= 32'b0;
    end else if(we && waddr!=0) begin
        reg32[waddr] <= wdata;
    end
end

endmodule
