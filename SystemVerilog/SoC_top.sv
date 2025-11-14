// ============================================================
// SoC_top.sv
//  - Mantiene SPI_top intacto (misma invocación a seven_segment_display).
//  - Latch al subir SS, CDC a 'clk' y write al regfile del CPU.
// ============================================================
module SoC_top (
    input  logic        clk,        // reloj CPU
    input  logic        reset,      // reset activo-alto del sistema

    // --- SPI físico desde Arduino ---
    input  logic        mosi,
    input  logic        sck,
    input  logic        req,
    input  logic        ss,

    // --- Salidas a placa ---
    output logic        ack,            // del handshake SPI
    output logic [6:0]  sev_seg_md,     // display 7seg del SPI_top

    // (opcional) debug
    output logic [31:0] alu_result_out
);

    // ========================================================
    // 1) SPI_top intacto (NO LO MODIFICAMOS)
    // ========================================================
    logic        spi_rst_n;            // SPI_io usa reset activo en bajo
    logic [3:0]  master_data_reg;      // nibble en dominio sck

    assign spi_rst_n = ~reset;         // convierte reset alto del sistema a bajo para SPI

    SPI_top u_spi_top (
        .rst(spi_rst_n),               // igual que en tu diseño original
        .mosi(mosi),
        .sck(sck),
        .req(req),
        .ss(ss),
        .ack(ack),
        .master_data_reg(master_data_reg),
        .sev_seg_md(sev_seg_md)        // MISMA invocación al seven_segment_display
    );

    // ========================================================
    // 2) Latch del nibble al FIN de frame y CDC a clk
    //    (para no mostrar el shift en vivo y dar dato estable al CPU)
    // ========================================================
    logic [3:0] md_latched_sck;
    logic       md_toggle_sck;

    // Captura del nibble al flanco ascendente de SS (fin de frame)
    always_ff @(posedge ss or posedge reset) begin
        if (reset) begin
            md_latched_sck <= 4'd0;
            md_toggle_sck  <= 1'b0;
        end else begin
            md_latched_sck <= master_data_reg;
            md_toggle_sck  <= ~md_toggle_sck; // evento "nuevo nibble listo"
        end
    end

    // Sincronización del toggle + dato a 'clk' (CDC)
    logic tog_meta, tog_sync, tog_sync_d;
    logic [3:0] md_meta_clk, md_sync_clk;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tog_meta    <= 1'b0;
            tog_sync    <= 1'b0;
            tog_sync_d  <= 1'b0;
            md_meta_clk <= 4'd0;
            md_sync_clk <= 4'd0;
        end else begin
            // toggle
            tog_meta    <= md_toggle_sck;
            tog_sync    <= tog_meta;
            tog_sync_d  <= tog_sync;
            // dato (doble registro)
            md_meta_clk <= md_latched_sck;
            md_sync_clk <= md_meta_clk;
        end
    end

    wire spi_nibble_valid_clk = (tog_sync ^ tog_sync_d); // pulso de 1 ciclo en clk

    // ========================================================
    // 3) CPU con puerto de escritura externa al regfile
    //    (prioridad al SPI cuando hay nibble válido)
    // ========================================================
    localparam logic [3:0] SPI_REG_DST = 4'hE;   // R14 por defecto (cámbialo si quieres)

    cpu_armv4 u_cpu (
        .clk(clk),
        .reset(reset),

        // --- Puerto de escritura externa al regfile (nuevo) ---
        .ext_wr_en  (spi_nibble_valid_clk),
        .ext_wr_addr(SPI_REG_DST),
        .ext_wr_data({28'd0, md_sync_clk}),

        // (opcional) debug
        .alu_result_out(alu_result_out)
    );

endmodule
