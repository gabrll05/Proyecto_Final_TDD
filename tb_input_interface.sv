// ============================================================
// tb_input_interface.v — test de integración PS/2 completo
// ============================================================
`timescale 1ns/1ps
module tb_input_interface;

  reg clk, reset;
  reg ps2_clk, ps2_data;
  wire [7:0] key_value;
  wire key_valid, is_operator;

  // --- Instancia del bloque completo ---
  input_interface uut (
    .clk(clk),
    .reset(reset),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .key_value(key_value),
    .key_valid(key_valid),
    .is_operator(is_operator)
  );

  // reloj 50 MHz
  always #10 clk = ~clk;

  // --- Generador de bit PS/2 (idéntico al del test anterior) ---
  task send_bit(input bit val);
    begin
      ps2_data = val;
      ps2_clk = 1; #50000;   // alto 50 µs
      ps2_clk = 0; #50000;   // bajo 50 µs
    end
  endtask

  // --- Enviar un byte completo ---
  task send_byte(input [7:0] code);
    integer i;
    reg parity;
    begin
      parity = ~^code;
      send_bit(0);
      for (i=0; i<8; i=i+1) send_bit(code[i]);
      send_bit(parity);
      send_bit(1);
      #(200000);
    end
  endtask

  // --- Mensaje al detectar tecla ---
  always @(posedge key_valid)
    $display("🔹 Tecla traducida: %s (ASCII=%h, operador=%b)  t=%0t",
             key_value, key_value, is_operator, $time);

  // --- Secuencia de prueba ---
  initial begin
    clk = 0; reset = 1; ps2_clk = 1; ps2_data = 1;
    #100 reset = 0;

    $display("=== Test input_interface ===");

    // Simular envío de scancodes
    send_byte(8'h1E);  // tecla "2"
    send_byte(8'h79);  // tecla "+"
    send_byte(8'h26);  // tecla "3"
    send_byte(8'h5A);  // tecla "Enter"

    #200000;
    $display("=== Fin del test ===");
    $stop;
  end
endmodule
