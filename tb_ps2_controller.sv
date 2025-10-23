// ============================================================
// tb_ps2_controller.sv — versión con mensaje "Tecla detectada"
// ============================================================
`timescale 1ns/1ps
module tb_ps2_controller;

  logic clk, reset;
  logic ps2_clk, ps2_data;
  logic [7:0] scancode;
  logic valid;

  // --- Instancia del módulo bajo prueba ---
  ps2_controller uut (
    .clk(clk),
    .reset(reset),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .scancode(scancode),
    .valid(valid)
  );

  // --- Reloj de sistema 50 MHz ---
  always #10 clk = ~clk;

  // --- Generador de bit individual PS/2 ---
  task send_bit(input bit val);
    begin
      ps2_data = val;
      ps2_clk = 1; #50000;   // alto 50 µs
      ps2_clk = 0; #50000;   // bajo 50 µs
    end
  endtask

  // --- Enviar un byte PS/2 (paquete completo) ---
  task send_byte(input [7:0] code);
    integer i;
    reg parity;
    begin
      parity = ~^code; // paridad impar
      // bit de inicio
      send_bit(0);
      // 8 bits de datos (LSB primero)
      for (i=0; i<8; i=i+1) send_bit(code[i]);
      // bit de paridad
      send_bit(parity);
      // bit de stop
      send_bit(1);
      // pausa entre bytes
      #(200000);
    end
  endtask

  // --- Mostrar mensaje cuando se detecte una tecla ---
  always @(posedge valid) begin
    $display("🔹 Tecla detectada en t=%0t | Código = %h", $time, scancode);
  end

  // --- Secuencia principal ---
  initial begin
    clk = 0;
    reset = 1;
    ps2_clk = 1;
    ps2_data = 1;
    #100 reset = 0;

    $display("=== Test Controlador PS/2 ===");
    $monitor("t=%0t | ps2_clk=%b ps2_data=%b valid=%b scancode=%h",
             $time, ps2_clk, ps2_data, valid, scancode);

    // Simular envío de la tecla 'A' (scancode 0x1C)
    send_byte(8'h1C);

    // Esperar al pulso de validación y finalizar
    wait(valid == 1);
    #100;
    $display("✅ Tecla recibida correctamente: %h", scancode);

    $stop;
  end
endmodule
