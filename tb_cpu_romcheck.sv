// ============================================================
// tb_cpu_romcheck.sv
// Testbench para verificar lectura de ROM y ejecución de CPU ARMv4 mínima
// ============================================================

`timescale 1ns/1ps
module tb_cpu_romcheck;

    // Señales de prueba
    logic clk;
    logic reset;
    logic [31:0] result;

    // Instancia de la CPU
    cpu_armv4 uut (
        .clk(clk),
        .reset(reset),
        .alu_result_out(result)
    );

    // ============================================================
    // Generador de reloj
    // ============================================================
    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz simulado

    // ============================================================
    // Reset y simulación principal
    // ============================================================
    initial begin
        $display("\n==============================================");
        $display("🚀  INICIO DE SIMULACIÓN - PRUEBA ROM + CPU");
        $display("==============================================\n");

        reset = 1;
        #20;
        reset = 0;

        // Ejecutar durante 2000 ns
        #2000;

        $display("\n==============================================");
        $display("✅ FIN DE SIMULACIÓN");
        $display("==============================================\n");
        $stop;
    end

    // ============================================================
    // Monitoreo principal
    // ============================================================
    // Imprime el estado actual de:
    // - PC (program counter)
    // - Instrucción leída desde la ROM
    // - Resultado actual de la ALU
    // - Registro destino al que se escribe
    // ============================================================
    always_ff @(posedge clk) begin
        if (!reset) begin
            $display("t=%0t | PC=%0d | Instr=%h | ALU=%0d | WR_en=%b | RegW=%0d",
                     $time,
                     uut.pc,
                     uut.instr,
                     uut.alu_result_out,
                     uut.reg_wr_en,
                     uut.reg_wr);
        end
    end

    // ============================================================
    // Monitoreo adicional del banco de registros
    // ============================================================
    always_ff @(posedge clk) begin
        if (!reset && uut.reg_wr_en)
            $display("📝 Escritura en R%0d = %0d (0x%h) @t=%0t",
                     uut.reg_wr,
                     uut.alu_result_out,
                     uut.alu_result_out,
                     $time);
    end

endmodule
