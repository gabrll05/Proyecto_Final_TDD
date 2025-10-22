// ============================================================
// tb_regfile.v  (Versión final compatible con Quartus Verilog parser)
// ============================================================
`timescale 1ns/1ps
module tb_regfile;

    reg clk, reset;
    reg [2:0] rd_a, rd_b, wr;
    reg [31:0] wr_data;
    wire [31:0] out_a, out_b;
    reg wr_en;

    // Instancia del módulo regfile
    regfile uut (
        .clk(clk), 
        .reset(reset),
        .rd_addr_a(rd_a), 
        .rd_addr_b(rd_b),
        .rd_data_a(out_a), 
        .rd_data_b(out_b),
        .wr_addr(wr), 
        .wr_data(wr_data), 
        .wr_en(wr_en)
    );

    // Generador de reloj
    always #5 clk = ~clk;

    initial begin
        $display("=====================================");
        $display("  Test del Banco de Registros ARMv4  ");
        $display("=====================================");

        clk = 0; 
        reset = 1; 
        wr_en = 0;
        #10 reset = 0;

        // Escribir en R0 = 25
        wr = 3'd0; wr_data = 32'd25; wr_en = 1;
        #10 wr_en = 0;

        // Escribir en R1 = 15
        wr = 3'd1; wr_data = 32'd15; wr_en = 1;
        #10 wr_en = 0;

        // Leer R0 y R1
        rd_a = 3'd0; 
        rd_b = 3'd1;
        #10 $display("Lectura R0=%0d, R1=%0d", out_a, out_b);

        // Escribir en R2 = R0 + R1
        wr = 3'd2; 
        wr_data = out_a + out_b; 
        wr_en = 1;
        #10 wr_en = 0;

        // Leer R2
        rd_a = 3'd2; 
        rd_b = 3'd2;
        #10 $display("Resultado R2=%0d", out_a);

        $display("=====================================");
        $display(" Fin del Test del Banco de Registros ");
        $display("=====================================");
        $stop;
    end

endmodule
