`timescale 1ns/1ps
module tb_ps2_decoder;

  reg clk, reset;
  reg [7:0] scancode;
  reg valid;
  wire [7:0] key_value;
  wire key_valid;
  wire is_operator;

  ps2_decoder uut (
    .clk(clk),
    .reset(reset),
    .scancode(scancode),
    .valid(valid),
    .key_value(key_value),
    .key_valid(key_valid),
    .is_operator(is_operator)
  );

  // reloj 50 MHz
  always #10 clk = ~clk;

  initial begin
    clk = 0; reset = 1; valid = 0; scancode = 8'h00;
    #60 reset = 0;
    $display("=== Test ps2_decoder ===");

    // --- Tecla "2"
    scancode = 8'h1E;
    valid = 1; #50; valid = 0;   // mantener 50 ns (>=2 ciclos)
    wait (key_valid == 1);
    $display("Tecla detectada: código=%h valor=%h operador=%b",
             scancode, key_value, is_operator);

    // --- Tecla "+"
    scancode = 8'h79;
    valid = 1; #50; valid = 0;
    wait (key_valid == 1);
    $display("Tecla detectada: código=%h valor=%h operador=%b",
             scancode, key_value, is_operator);

    // --- Tecla "Enter"
    scancode = 8'h5A;
    valid = 1; #50; valid = 0;
    wait (key_valid == 1);
    $display("Tecla detectada: código=%h valor=%h operador=%b",
             scancode, key_value, is_operator);

    $display("=== Fin del test ===");
    $stop;
  end
endmodule
