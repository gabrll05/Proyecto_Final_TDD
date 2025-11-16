// ============================================================
// top_fpga_cpu_test.sv  (versión corregida)
// Prueba del procesador ARMv4 en FPGA
// ============================================================
module top_fpga_cpu_test(
    input  logic CLOCK_50,    // reloj base de la FPGA
    input  logic [0:0] KEY,   // botón de reset (KEY0)
    output logic [9:0] LEDR   // LEDs de salida
);
    // =======================================================
    // Señales internas
    // =======================================================
    logic rst_n;
    assign rst_n = KEY[0];    // KEY0 es activo en bajo (0 = reset)

    logic clk_slow;
    logic [31:0] result;

    // =======================================================
    // Divisor de reloj para ejecución lenta
    // =======================================================
    clock_divider u_div (
        .clk_in (CLOCK_50),
        .rst_n  (rst_n),
        .clk_out(clk_slow)
    );

    // =======================================================
    // CPU ARMv4 mínima
    // =======================================================
    cpu_armv4 u_cpu (
        .clk  (clk_slow),
        .reset(~rst_n),          // reset activo en alto
        .alu_result_out(result)
    );

    // =======================================================
    // LEDs: muestran el resultado de la ALU
    // =======================================================
    assign LEDR = result[9:0];   // visualiza parte baja (ej: 5 = 0000000101)
endmodule
