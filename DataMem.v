module DataMem(
    input wire clk,
    input wire ce,
    input wire we,
    input wire [31:0] addr,
    input wire [31:0] dataIn,
    output wire [31:0] dataOut
);

reg [31:0] ram [0:1023];

assign dataOut = (ce && !we) ? ram[addr[11:2]] : 32'b0;

always @(posedge clk) begin
    if(ce && we)
        ram[addr[11:2]] <= dataIn;
end

endmodule