// ============================================================
// ram_data.sv
// RAM de datos simple de 256 palabras x 32 bits
// ============================================================
module ram_data (
    input  logic        clk,
    input  logic        we,          // write enable
    input  logic [7:0]  addr,        // dirección (256 posiciones)
    input  logic [31:0] data_in,     // dato de entrada
    output logic [31:0] data_out     // dato leído
);
    // ========================================================
    // Memoria interna
    // ========================================================
    logic [31:0] mem_array [0:255];   // accesible desde el testbench

    // Lectura combinacional
    assign data_out = mem_array[addr];

    // Escritura síncrona
    always_ff @(posedge clk) begin
        if (we)
            mem_array[addr] <= data_in;
    end

endmodule
