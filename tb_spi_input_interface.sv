`timescale 1ns/1ps
module tb_spi_input_interface;

  logic clk, rst;
  logic mosi, sck, req, ss;
  logic ack;
  logic [7:0] key_value;
  logic key_valid, is_operator;

  spi_input_interface uut (
    .clk(clk), .rst(rst),
    .mosi(mosi), .sck(sck),
    .req(req), .ss(ss), .ack(ack),
    .key_value(key_value),
    .key_valid(key_valid),
    .is_operator(is_operator)
  );

  always #10 clk = ~clk;

  task send_nibble(input [3:0] val);
    integer i;
    begin
      req = 1; ss = 0;
      for (i = 3; i >= 0; i--) begin
        mosi = val[i];
        #20 sck = 1; #20 sck = 0;
      end
      ss = 1;
      req = 0;
    end
  endtask

  initial begin
    clk = 0; rst = 0; sck = 0; req = 0; ss = 1; mosi = 0;
    #50 rst = 1;
    $display("=== Test SPI Input Interface ===");

    send_nibble(4'h1); #100;
    send_nibble(4'hA); #100;
    send_nibble(4'h2); #100;
    send_nibble(4'hE); #100;

    $display("=== Fin del test ===");
    $stop;
  end

  always @(posedge key_valid)
    $display("🔹 Tecla recibida: %s (ASCII=%h, op=%b) t=%0t",
             key_value, key_value, is_operator, $time);

endmodule
