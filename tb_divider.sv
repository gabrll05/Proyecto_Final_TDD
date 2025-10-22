// ============================================================
// tb_divider.sv
// Testbench para módulo divisor
// ============================================================
`timescale 1ns/1ps
module tb_divider;

    logic clk, reset, start;
    logic [31:0] a, b;
    logic [31:0] q, r;
    logic done;

    divider uut (
        .clk(clk), .reset(reset),
        .start(start),
        .dividend(a),
        .divisor(b),
        .quotient(q),
        .remainder(r),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; start = 0; a = 0; b = 0;
        #10 reset = 0;

        $display("=== Test División Iterativa ===");

        // Caso 1: 25 / 5
        a = 32'd25; b = 32'd5; start = 1;
        #10 start = 0;
        wait(done);
        #5 $display("25 / 5 = %d, residuo = %d", q, r);

        // Caso 2: 100 / 7
        a = 32'd100; b = 32'd7; start = 1;
        #10 start = 0;
        wait(done);
        #5 $display("100 / 7 = %d, residuo = %d", q, r);

        $stop;
    end
endmodule
