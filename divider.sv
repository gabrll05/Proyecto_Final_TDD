
module divider #(
  parameter int N = 32
)(
  input  logic [N-1:0] A,   // dividendo
  input  logic [N-1:0] B,   // divisor
  output logic [N-1:0] Q,   // cociente
  output logic [N-1:0] R,   // residuo
  output logic         div0 // 1 si B==0
);

  always_comb begin
    if (B == '0) begin
      Q    = '0;
      R    = A;
      div0 = 1'b1;
    end else begin
      // División entera sin signo (sintetizable en Quartus)
      Q    = A / B;
      R    = A % B;
      div0 = 1'b0;
    end
  end

endmodule
