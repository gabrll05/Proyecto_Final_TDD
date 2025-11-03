// ============================================================
// input_interface.sv
// Interfaz de entrada PS/2 completa para Calculadora ARM-V4
// Combina: ps2_controller + ps2_decoder
// ============================================================
spi_input_interface u_input (
    .clk(clk),
    .rst(reset),
    .mosi(MOSI),
    .sck(SCK),
    .req(REQ),
    .ss(SS),
    .ack(ACK),
    .key_value(key_value),
    .key_valid(key_valid),
    .is_operator(is_operator)
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
