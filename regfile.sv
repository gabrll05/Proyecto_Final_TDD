// ============================================================
// regfile.sv
// Banco de registros de 16 x 32 bits
// ============================================================
module regfile (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  rd_addr_a,   // dirección lectura A
    input  logic [3:0]  rd_addr_b,   // dirección lectura B
    output logic [31:0] rd_data_a,   // salida A
    output logic [31:0] rd_data_b,   // salida B
    input  logic [3:0]  wr_addr,     // dirección de escritura
    input  logic [31:0] wr_data,     // dato a escribir
    input  logic        wr_en        // habilitación de escritura
);

    // ========================================================
    // Registros
    // ========================================================
    logic [31:0] registers [0:15];

    // Lecturas combinacionales
    assign rd_data_a = registers[rd_addr_a];
    assign rd_data_b = registers[rd_addr_b];

    // Escritura síncrona
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            for (int i = 0; i < 16; i++)
                registers[i] <= 0;
        else if (wr_en)
            registers[wr_addr] <= wr_data;
    end

endmodule
