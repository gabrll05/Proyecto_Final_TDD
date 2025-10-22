// ============================================================
// tb_alu.sv (versión corregida con división secuencial funcional)
// ============================================================
`timescale 1ns/1ps
module tb_alu;

    logic clk, reset;
    logic [31:0] a, b;
    logic [3:0]  sel;
    logic [31:0] result;
    logic z, n, c, v, busy;

    // Instancia de la ALU con divisor secuencial
    alu uut (
        .clk(clk),
        .reset(reset),
        .a(a), 
        .b(b), 
        .sel(sel),
        .result(result),
        .z_flag(z), 
        .n_flag(n),
        .c_flag(c), 
        .v_flag(v),
        .busy(busy)
    );

    // Generador de reloj
    always #5 clk = ~clk;

    initial begin
        $display("=== Test ALU ARMv4 ===");

        clk = 0;
        reset = 1;
        #10 reset = 0;

        // Suma
        a = 32'd10; b = 32'd5; sel = 4'b0000;
        #10 $display("ADD: %d + %d = %d", a, b, result);

        // Resta
        a = 32'd20; b = 32'd7; sel = 4'b0001;
        #10 $display("SUB: %d - %d = %d", a, b, result);

        // Multiplicación
        a = 32'd6; b = 32'd4; sel = 4'b0010;
        #10 $display("MUL: %d * %d = %d", a, b, result);

        // MOV
        a = 32'd0; b = 32'd99; sel = 4'b0011;
        #10 $display("MOV: %d", result);

        // CMP
        a = 32'd10; b = 32'd10; sel = 4'b0100;
        #10 $display("CMP: Z=%b, N=%b", z, n);

        // División secuencial
        a = 32'd100; b = 32'd7; sel = 4'b0101;
        #10 $display("DIV iniciando: %d / %d", a, b);
        wait(!busy);  // esperar hasta que la división termine
        #10 $display("DIV: %d / %d = %d", a, b, result);

        $display("=== Fin de test ===");
        $stop;
    end
endmodule
