`include "define.v"

module soc_tb;
reg clk;
reg rst;
wire [31:0] regaData_out;
wire jalr_ctrl_out;

initial begin
    clk = 0;
    rst = 1;
    #100 rst = 0;
    repeat (80) @(posedge clk);
    $finish;
end

always #10 clk = ~clk;

MIPS mips0(
    .clk(clk),
    .rst(rst),
    .regaData_out(regaData_out),
    .jalr_ctrl_out(jalr_ctrl_out)
);

endmodule
