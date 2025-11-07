`timescale 1ns/1ps
module tb_alu_isolated;

  // ----------------- Parámetros -----------------
  localparam int N = 32;

  // ----------- Señales del DUT ------------------
  logic              clk, reset;
  logic [N-1:0]      A, B;
  logic              CIN_BIN;
  logic [3:0]        OP;
  logic [N-1:0]      Y;
  logic [3:0]        FLAGS;   // {Z,N,C,V}

  // ------------- Instancia del DUT --------------
  alu_core #(.N(N)) dut (
    .clk     (clk),
    .reset   (reset),
    .A       (A),
    .B       (B),
    .CIN_BIN (CIN_BIN),
    .OP      (OP),
    .Y       (Y),
    .FLAGS   (FLAGS)
  );

  // ----------------- Reloj ----------------------
  initial clk = 0;
  always #5 clk = ~clk;   // 100 MHz

  // ------------- Utilidad de estímulos ----------
  task automatic vec(
    input logic [N-1:0] a_i,
    input logic [N-1:0] b_i,
    input logic  [3:0]  op_i,
    input logic         cin_i
  );
  begin
    A = a_i; B = b_i; OP = op_i; CIN_BIN = cin_i;
    @(posedge clk); // dispara los prints internos en el flanco
    #1;             // margen de propagación
  end
  endtask

  // ------------- Códigos de operación -----------
  localparam logic [3:0]
    OP_ADD = 4'd0, OP_SUB = 4'd1, OP_MUL = 4'd2, OP_DIV = 4'd3, OP_MOD = 4'd4,
    OP_AND = 4'd5, OP_OR  = 4'd6, OP_XOR = 4'd7, OP_SLL = 4'd8, OP_SRL = 4'd9;

  // ---------------- Estímulos -------------------
  initial begin
    $display("=== tb_alu_isolated -> alu_core (N=%0d) ===", N);

    // Reset
    reset = 1'b1; CIN_BIN = 1'b0; A = '0; B = '0; OP = OP_ADD;
    repeat (2) @(posedge clk);
    reset = 1'b0;
    @(posedge clk);

    // ADD
    vec(32'd3,      32'd2,      OP_ADD, 1'b0);
    vec(32'hFFFF_FFFF, 32'd1,   OP_ADD, 1'b0);

    // SUB
    vec(32'd7,      32'd4,      OP_SUB, 1'b0);
    vec(32'd0,      32'd1,      OP_SUB, 1'b0);

    // MUL (trunc a N bits)
    vec(32'd12,     32'd5,      OP_MUL, 1'b0);
    vec(32'h00FF,   32'h0102,   OP_MUL, 1'b0);

    // DIV / MOD
    vec(32'd25,     32'd4,      OP_DIV, 1'b0);
    vec(32'd25,     32'd4,      OP_MOD, 1'b0);

    // DIV0 / MOD0 para ver el mensaje
    vec(32'd123,    32'd0,      OP_DIV, 1'b0);
    vec(32'd123,    32'd0,      OP_MOD, 1'b0);

    // Lógicas
    vec(32'h00F0,   32'h0F0F,   OP_AND, 1'b0);
    vec(32'h00F0,   32'h0F0F,   OP_OR , 1'b0);
    vec(32'h00F0,   32'h0F0F,   OP_XOR, 1'b0);

    // Shifts (cantidad en B)
    vec(32'h0001,   32'd3,      OP_SLL, 1'b0);
    vec(32'h8000_0000, 32'd2,   OP_SRL, 1'b0);

    // Fin
    repeat (2) @(posedge clk);
    $display("=== Fin tb_alu_isolated ===");
    $stop;
  end

  // (Opcional) VCD
  initial begin
    $dumpfile("tb_alu_isolated.vcd");
    $dumpvars(0, tb_alu_isolated);
  end

endmodule
