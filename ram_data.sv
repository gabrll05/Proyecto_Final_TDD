// ============================================================
// ram_data.sv
// Memoria de datos para instrucciones LDR / STR
// ============================================================

module ram_data (
    input  logic        clk,
    input  logic        wr_en,
    input  logic [31:0] addr,
    input  logic [31:0] wr_data,
    output logic [31:0] rd_data
);
    // Memoria simple de 256 posiciones (puede ajustarse)
    logic [31:0] mem [0:255];

    // Escritura sincrónica
    always_ff @(posedge clk) begin
        if (wr_en) begin
            mem[addr] <= wr_data;
            $display("💾 STORE: MEM[%0d] <= %0d (0x%0h) @t=%0t",
                     addr, wr_data, wr_data, $time);
        end
    end

    // Lectura combinacional
    assign rd_data = mem[addr];

    // 🔍 Bloque de depuración opcional:
    // Muestra el valor actual de la memoria en una dirección concreta
    always_ff @(posedge clk) begin
        if (!wr_en && mem[addr] !== 32'bx)
            $display("🔍 MEM[%0d] = %0d (0x%0h) @t=%0t",
                     addr, mem[addr], mem[addr], $time);
    end

endmodule
