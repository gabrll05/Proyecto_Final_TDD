module restador #(
  parameter int N = 4
) (
  input  logic [N-1:0] A,
  input  logic [N-1:0] B,
  input  logic         Bin,     
  output logic [N-1:0] Y,
  output logic         Bout,    
  output logic         Z,
  output logic         Nf,
  output logic         V,
  output logic         C      
);

  logic [N:0] b; 
  assign b[0] = Bin;

  genvar i;
  generate
    for (i = 0; i < N; i++) begin : RB_SUB

      assign Y[i]   = A[i] ^ B[i] ^ b[i];

      assign b[i+1] = ((~A[i]) & B[i]) | ((~(A[i] ^ B[i])) & b[i]);
    end
  endgenerate

  assign Bout = b[N];
  assign C    = ~b[N];                     
  assign Nf   = Y[N-1];
  assign Z    = ~(|Y);
  assign V    = (A[N-1] ^ B[N-1]) & (A[N-1] ^ Y[N-1]);

endmodule
