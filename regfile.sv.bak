// ============================================================
// regfile.sv
// Banco de registros para CPU ARMv4 mínima
// ============================================================

module regfile #(
    parameter N = 8,              // cantidad de registros
    parameter W = 32              // ancho de cada registro
)(
    input  logic              clk,       // reloj
    input  logic              reset,     // reset sincrónico
    // Lectura
    input  logic [$clog2(N)-1:0] rd_addr_a,
    input  logic [$clog2(N)-1:0] rd_addr_b,
    output logic [W-1:0]      rd_data_a,
    output logic [W-1:0]      rd_data_b,
    // Escritura
    input  logic [$clog2(N)-1:0] wr_addr,
    input  logic [W-1:0]      wr_data,
    input  logic              wr_en
);

    // Memoria interna de registros
    logic [W-1:0] regs [N-1:0];

    // Lectura combinacional
    assign rd_data_a = regs[rd_addr_a];
    assign rd_data_b = regs[rd_addr_b];

    // Escritura sincrónica
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < N; i++)
                regs[i] <= 0;
        end else if (wr_en) begin
            regs[wr_addr] <= wr_data;
        end
    end

endmodule
