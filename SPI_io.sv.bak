// ============================================================
// SPI_io.sv
// Módulo de comunicación SPI simplificado con handshake
// Diseñado para comunicación FPGA <-> Arduino
// ============================================================

module SPI_io (
    input  logic rst,                    // reset activo en alto
    input  logic mosi,                   // dato serial desde Arduino
    input  logic sck,                    // reloj serial
    input  logic req,                    // solicitud Arduino → FPGA
    input  logic ss,                     // chip select activo en bajo
    output logic ack,                    // acknowledge FPGA → Arduino
    output logic [3:0] master_data_register  // datos recibidos (4 bits)
);

    // ===============================================================
    // Señales internas
    // ===============================================================
    logic [5:0] cs, ns;      // registro de estado (FSM)
    logic [3:0] md, next_md; // registro de datos

    // ===============================================================
    // Codificación one-hot de los estados (S0–S5)
    // ===============================================================
    localparam [5:0]
        S0 = 6'b000001,
        S1 = 6'b000010,
        S2 = 6'b000100,
        S3 = 6'b001000,
        S4 = 6'b010000,
        S5 = 6'b100000;

    // ===============================================================
    // REGISTRO DE ESTADO
    // ===============================================================
    always_ff @(posedge sck or negedge rst) begin
        if (!rst)
            cs <= S0;
        else
            cs <= ns;
    end

    // ===============================================================
    // REGISTRO DE DATOS (shift register)
    // ===============================================================
    assign next_md = (!rst) ? 4'b0000 :
                     (!ss)  ? {md[2:0], mosi} :
                               md;

    always_ff @(posedge sck or negedge rst) begin
        if (!rst)
            md <= 4'b0000;
        else
            md <= next_md;
    end

    // ===============================================================
    // LÓGICA DE PRÓXIMO ESTADO (FSM estructural)
    // ===============================================================
    logic nmosi, req_active;
    assign nmosi = ~mosi;
    assign req_active = req & rst; // activo cuando req=1 y rst=1

    assign ns[0] = req_active & (mosi & (cs[5] | cs[2] | cs[1] | cs[0]));
    assign ns[1] = req_active & (nmosi & (cs[0] | cs[4] | cs[5]));
    assign ns[2] = req_active & (nmosi & cs[1]);
    assign ns[3] = req_active & (nmosi & (cs[2] | cs[3]));
    assign ns[4] = req_active & (mosi & cs[3]);
    assign ns[5] = req_active & (mosi & cs[4]);

    // ===============================================================
    // SALIDAS
    // ===============================================================
    assign ack = cs[5];                // acknowledge activo en S5
    assign master_data_register = md;  // datos capturados (4 bits)

endmodule
