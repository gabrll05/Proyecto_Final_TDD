`timescale 1ns/1ps
module tb_alu_isolated;

    logic clk, reset;
    logic [31:0] a, b;
    logic [7:0] imm;
    logic [3:0] instr;
    logic [31:0] result;
    logic busy, z, n, c, v;

    alu uut (
        .clk(clk), .reset(reset),
        .a(a), .b(b), .imm(imm),
        .instr(instr), .sel(4'b0000),
        .result(result),
        .busy(busy), .z_flag(z), .n_flag(n), .c_flag(c), .v_flag(v)
    );

    always #5 clk = ~clk;

    initial begin
        $display("=== Test ALU aislada ===");
        clk = 0; reset = 1;
        #10 reset = 0;

        // MOV inmediato
        instr = 4'b0011; imm = 8'd4;
        a = 32'd0; b = 32'd0;
        #10;
        $display("MOV #4 -> result=%d", result);

        // ADD
        instr = 4'b0000;
        a = 32'd3; b = 32'd2;
        #10;
        $display("ADD 3+2 -> result=%d", result);

        // SUB
        instr = 4'b0001;
        a = 32'd7; b = 32'd4;
        #10;
        $display("SUB 7-4 -> result=%d", result);

        $stop;
    end
endmodule
