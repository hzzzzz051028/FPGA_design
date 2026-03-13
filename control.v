`include "define.v"

module control(
    input wire [5:0] opcode,
    input wire [5:0] funct,
    input wire [4:0] rs,

    output reg regwrite,
    output reg memwrite,
    output reg memread,
    output reg mfc0,
    output reg mtc0,
    output reg eret,
    output reg syscall,
    output reg ll,
    output reg sc,
    output reg jalr_ctrl 
);

always @(*) begin
    regwrite = 0;
    memwrite = 0;
    memread  = 0;
    mfc0 = 0;
    mtc0 = 0;
    eret = 0;
    syscall = 0;
    ll = 0;
    sc = 0;
    jalr_ctrl = 0;

    case(opcode)

        `Inst_ll: begin
            memread = 1;
            regwrite = 1;
            ll = 1;
        end

        `Inst_sc: begin
            sc = 1;
            regwrite = 1;
        end

        `Inst_cop0: begin
            if(rs == `Inst_mfc0) begin
                mfc0 = 1;
                regwrite = 1;
            end
            else if(rs == `Inst_mtc0) begin
                mtc0 = 1;
            end
            else if(rs == `Inst_eret_rs && funct == `Inst_eret_fun) begin
                eret = 1;
            end
        end

        `Inst_r: begin
            case(funct)
                `Inst_jalr: begin
                    jalr_ctrl = 1;
                    regwrite = 1;
                    $display("JALR detected!");
                end
            endcase
        end

    endcase
end

endmodule