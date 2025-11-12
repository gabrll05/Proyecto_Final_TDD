// ============================================================
// alu_core.sv — combinacional (sin latches) + prints en sim
// ============================================================
module alu_core #(
  parameter int N = 16
) (
  input  logic         clk,     // para prints (sim)
  input  logic         reset,   // para prints (sim)
  input  logic [N-1:0] A,
  input  logic [N-1:0] B,
  input  logic         CIN_BIN,
  input  logic  [3:0]  OP,
  output logic [N-1:0] Y,
  output logic  [3:0]  FLAGS
);

  localparam logic [3:0]
    OP_NOP = 4'd0, OP_ADD = 4'd1, OP_SUB = 4'd2, OP_MUL = 4'd3, OP_DIV = 4'd4, OP_MOD = 4'd5,
    OP_AND = 4'd6, OP_OR  = 4'd7, OP_XOR = 4'd8, OP_SLL = 4'd9, OP_SRL = 4'd10;

  // ---- SUMA/RESTA ----
  logic [N-1:0] y_add, y_sub;
  logic z_add, n_add, c_add, v_add;
  logic z_sub, n_sub, c_sub, v_sub, bout_sub;

  sumador  #(.N(N)) u_add(.A(A), .B(B), .Cin(CIN_BIN),
                          .Y(y_add), .Cout(), .Z(z_add), .Nf(n_add), .V(v_add), .C(c_add));

  restador #(.N(N)) u_sub(.A(A), .B(B), .Bin(CIN_BIN),
                          .Y(y_sub), .Bout(bout_sub), .Z(z_sub), .Nf(n_sub), .V(v_sub), .C(c_sub));

  // ---- MULTIPLICACIÓN por sumas ----
  logic [2*N-1:0] P2N;
  multiplicador_sumas #(.N(N)) u_mul (.A(A), .B(B), .P(P2N));

  logic [N-1:0] y_mul_trunc;
  logic         mul_overflow;
  assign y_mul_trunc  = P2N[N-1:0];
  assign mul_overflow = |P2N[2*N-1:N];

  // ---- DIV / MOD ----
  logic [N-1:0] Q_div, R_mod;
  logic div0;
  divider #(.N(N)) u_divmod(.A(A), .B(B), .Q(Q_div), .R(R_mod), .div0(div0));

  // ---- LÓGICAS / SHIFTS ----
  logic [N-1:0] y_and, y_or, y_xor, y_sll, y_srl;
  logic_ops #(.N(N)) u_logic (.A(A), .B(B), .ANDY(y_and), .ORY(y_or), .XORY(y_xor), .SLLY(y_sll), .SRLY(y_srl));

  // ---- MUX resultado y flags (COMBINACIONAL) ----
  always_comb begin
    Y     = '0;
    FLAGS = 4'b0000;

    unique case (OP)
      OP_NOP: ; // defaults
      OP_ADD: begin
        Y     = y_add;
        FLAGS = {z_add, n_add, c_add, v_add};
      end
      OP_SUB: begin
        Y     = y_sub;
        FLAGS = {z_sub, n_sub, c_sub, v_sub};
      end
      OP_MUL: begin
        Y     = y_mul_trunc;
        FLAGS = {(y_mul_trunc=='0), y_mul_trunc[N-1], mul_overflow, 1'b0};
      end
      OP_DIV: begin
        Y     = Q_div;
        FLAGS = {(Q_div=='0),       Q_div[N-1],       1'b0,         1'b0};
      end
      OP_MOD: begin
        Y     = R_mod;
        FLAGS = {(R_mod=='0),       R_mod[N-1],       1'b0,         1'b0};
      end
      OP_AND: begin
        Y     = y_and;
        FLAGS = {(y_and=='0),       y_and[N-1],       1'b0,         1'b0};
      end
      OP_OR : begin
        Y     = y_or;
        FLAGS = {(y_or=='0),        y_or[N-1],        1'b0,         1'b0};
      end
      OP_XOR: begin
        Y     = y_xor;
        FLAGS = {(y_xor=='0),       y_xor[N-1],       1'b0,         1'b0};
      end
      OP_SLL: begin
        Y     = y_sll;
        FLAGS = {(y_sll=='0),       y_sll[N-1],       1'b0,         1'b0};
      end
      OP_SRL: begin
        Y     = y_srl;
        FLAGS = {(y_srl=='0),       y_srl[N-1],       1'b0,         1'b0};
      end
      default: ; // defaults
    endcase
  end

`ifndef SYNTHESIS
  // Prints solo para simulación
  always_ff @(posedge clk) begin
    if (!reset) begin
      unique case (OP)
        OP_ADD: $display("ALU: ADD %0d + %0d = %0d @t=%0t", A, B, Y, $time);
        OP_SUB: $display("ALU: SUB %0d - %0d = %0d @t=%0t", A, B, Y, $time);
        OP_MUL: $display("ALU: MUL %0d * %0d = %0d @t=%0t", A, B, Y, $time);
        OP_DIV: if (div0)
                  $display("ALU: DIV %0d / %0d -> DIV0 (Q=0, R=%0d) @t=%0t", A, B, A, $time);
                else
                  $display("ALU: DIV %0d / %0d = %0d @t=%0t", A, B, Y, $time);
        OP_MOD: if (div0)
                  $display("ALU: MOD %0d %% %0d -> DIV0 (R=%0d) @t=%0t", A, B, A, $time);
                else
                  $display("ALU: MOD %0d %% %0d = %0d @t=%0t", A, B, Y, $time);
        OP_AND: $display("ALU: AND 0x%0h & 0x%0h = 0x%0h @t=%0t", A, B, Y, $time);
        OP_OR : $display("ALU: OR  0x%0h | 0x%0h = 0x%0h @t=%0t", A, B, Y, $time);
        OP_XOR: $display("ALU: XOR 0x%0h ^ 0x%0h = 0x%0h @t=%0t", A, B, Y, $time);
        OP_SLL: $display("ALU: SLL %0d << %0d = %0d @t=%0t", A, B, Y, $time);
        OP_SRL: $display("ALU: SRL %0d >> %0d = %0d @t=%0t", A, B, Y, $time);
        default: ;
      endcase
    end
  end
`endif

endmodule
