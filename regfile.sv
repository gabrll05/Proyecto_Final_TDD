// ============================================================
// regfile.sv — versión con depuración (imprime escrituras)
// ============================================================

module regfile #(
    parameter N = 8,   // cantidad de registros
    parameter W = 32   // ancho de cada registro
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

    // Memoria interna
    logic [W-1:0] regs [N-1:0];

    // Lectura combinacional
    assign rd_data_a = regs[rd_addr_a];
    assign rd_data_b = regs[rd_addr_b];

    // Escritura sincrónica con mensajes de depuración
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < N; i++)
                regs[i] <= 0;
        end else if (wr_en) begin
            regs[wr_addr] <= wr_data;
            $display("📝 Escritura en R%0d = %0d (0x%0h) @t=%0t", wr_addr, wr_data, wr_data, $time);
        end
    end

    // Mostrar lectura (opcional, puedes comentar si es mucho)
    always_ff @(posedge clk) begin
        $display("📖 Lectura: A=R%0d=%0d | B=R%0d=%0d | wr_en=%b @t=%0t",
                 rd_addr_a, regs[rd_addr_a],
                 rd_addr_b, regs[rd_addr_b],
                 wr_en, $time);
    end

endmodule
