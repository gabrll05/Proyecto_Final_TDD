`timescale 1ns/1ps
module tb_vga_controller;

  reg clk, reset;
  wire [9:0] x, y;
  wire hsync, vsync, visible;

  vga_controller uut (
    .clk_25MHz(clk),
    .reset(reset),
    .x(x), .y(y),
    .hsync(hsync), .vsync(vsync),
    .visible(visible)
  );

  always #20 clk = ~clk;  // reloj de 25 MHz

  initial begin
    clk = 0; reset = 1; #100 reset = 0;
    $display("=== Test VGA Controller ===");
    repeat (1000) @(posedge clk);
    $display("x=%d y=%d hsync=%b vsync=%b visible=%b", x, y, hsync, vsync, visible);
    $stop;
  end
endmodule
	