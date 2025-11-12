// ============================================================
// input_interface.sv
// Interfaz de entrada PS/2 completa para Calculadora ARM-V4
// Combina: ps2_controller + ps2_decoder
// ============================================================
module input_interface (
    input  logic clk,
    input  logic reset,
    input  logic ps2_clk,
    input  logic ps2_data,
    output logic [7:0] key_value,   // ASCII del número u operador
    output logic       key_valid,   // 1 = nueva tecla
    output logic       is_operator  // 1 = operador (+,-,*,/,=)
);

    // Señales internas
    logic [7:0] scancode;
    logic       sc_valid;

    // ------------------------------------------------------------
    // Instancia del controlador PS/2 (lectura serial)
    // ------------------------------------------------------------
    ps2_controller u_ctrl (
        .clk       (clk),
        .reset     (reset),
        .ps2_clk   (ps2_clk),
        .ps2_data  (ps2_data),
        .scancode  (scancode),
        .valid     (sc_valid)
    );

    // ------------------------------------------------------------
    // Instancia del decodificador (traduce scancode → ASCII)
    // ------------------------------------------------------------
    ps2_decoder u_dec (
        .clk        (clk),
        .reset      (reset),
        .scancode   (scancode),
        .valid      (sc_valid),
        .key_value  (key_value),
        .key_valid  (key_valid),
        .is_operator(is_operator)
    );

endmodule
