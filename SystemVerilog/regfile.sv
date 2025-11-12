// ============================================================
// regfile.sv  - Banco de registros 16 x 32
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
    logic [31:0] registers [0:15];

    // Lecturas combinacionales
    assign rd_data_a = registers[rd_addr_a];
    assign rd_data_b = registers[rd_addr_b];

    // Escritura síncrona
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 16; i++)
                registers[i] <= 32'd0;
        end else if (wr_en) begin
            registers[wr_addr] <= wr_data;
        end
    end
endmodule
