// ============================================================
// spi_rx8_cdc.sv  - Receptor SPI 8 bits + handshake + CDC a clk
//  - Handshake: patrón 00011 con req=1 y ss=1 (ack=1 en S5)
//  - Datos: con ss=0, recibe 8 bits MSB-first por mosi en flanco posedge de sck
//  - CDC: genera pulso spi_byte_valid_clk y dato spi_byte_clk en dominio 'clk'
// ============================================================
module spi_rx8_cdc (
    // Reloj de la CPU
    input  logic        clk,        // dominio CPU
    input  logic        reset,      // activo en alto

    // Dominio SPI (desde maestro Arduino)
    input  logic        sck,
    input  logic        ss,         // activo en bajo
    input  logic        mosi,
    input  logic        req,

    // Handshake hacia el maestro
    output logic        ack,        // alto cuando FSM está en S5

    // Entrega en dominio CPU (clk):
    output logic        spi_byte_valid_clk, // pulso 1 ciclo en clk
    output logic [7:0]  spi_byte_clk        // byte estable en clk cuando 'valid'
);
    // -------------------- FSM Handshake (dominio sck) --------------------
    function automatic logic [5:0] one_hot (int index);
        return (6'b000001 << index);
    endfunction

    localparam logic [5:0] S0 = one_hot(0),
                           S1 = one_hot(1),
                           S2 = one_hot(2),
                           S3 = one_hot(3),
                           S4 = one_hot(4),
                           S5 = one_hot(5);

    logic [5:0] cs, ns;

    // -------------------- RX de datos (dominio sck) --------------------
    logic [7:0]  rx_shift_sck;
    logic [2:0]  bitcnt_sck;          // cuenta 0..7
    logic [7:0]  byte_buf_sck;        // último byte armado en sck
    logic        byte_toggle_sck;     // toggle para CDC cuando hay byte nuevo

    // Progreso de FSM + recepción en posedge sck
    always_ff @(posedge sck or posedge reset) begin
        if (reset) begin
            cs              <= S0;
            rx_shift_sck    <= 8'd0;
            bitcnt_sck      <= 3'd0;
            byte_buf_sck    <= 8'd0;
            byte_toggle_sck <= 1'b0;
        end else begin
            // Si req=0, volver a S0 (igual que tu SPI_io)
            if (!req) begin
                cs <= S0;
            end else begin
                // Cuando SS está alto (no hay frame), avanzar FSM de handshake
                if (ss) begin
                    cs <= ns; // handshake camina con sck y req activos
                    // No recibimos bits con SS alto
                    bitcnt_sck   <= 3'd0; // opcional: rearmar contador fuera de frame
                end
                // Cuando SS está en bajo, recibimos datos en cada flanco de sck
                else begin
                    // MSB-first: desplazar e insertar mosi en LSB
                    rx_shift_sck <= {rx_shift_sck[6:0], mosi};
                    bitcnt_sck   <= bitcnt_sck + 3'd1;

                    // Si completamos 8 bits (bitcnt previo 7 → ahora 0)
                    if (bitcnt_sck == 3'd7) begin
                        byte_buf_sck    <= {rx_shift_sck[6:0], mosi}; // byte armado
                        byte_toggle_sck <= ~byte_toggle_sck; // evento para CDC
                        bitcnt_sck      <= 3'd0;
                    end
                end
            end
        end
    end

    // Lógica de next-state (idéntica a tu SPI_io), combinacional
    assign ns[0] = mosi && (cs[5] || cs[2] || cs[1] || cs[0]);
    assign ns[1] = ~mosi && (cs[0] || cs[4] || cs[5]);
    assign ns[2] = ~mosi && cs[1];
    assign ns[3] = ~mosi && (cs[2] || cs[3]);
    assign ns[4] = mosi && cs[3];
    assign ns[5] = mosi && cs[4];

    assign ack   = cs[5];  // igual que SPI_io

    // -------------------- CDC a dominio 'clk' --------------------
    // Sincronizamos el toggle de sck → clk con dos FF
    logic tog_meta, tog_sync, tog_sync_d;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tog_meta     <= 1'b0;
            tog_sync     <= 1'b0;
            tog_sync_d   <= 1'b0;
        end else begin
            tog_meta   <= byte_toggle_sck;
            tog_sync   <= tog_meta;
            tog_sync_d <= tog_sync;
        end
    end
    wire new_byte_clk = (tog_sync ^ tog_sync_d);

    // Sincronizamos también el bus de datos (doble registro)
    logic [7:0] byte_meta, byte_sync;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_meta <= 8'd0;
            byte_sync <= 8'd0;
        end else begin
            byte_meta <= byte_buf_sck;
            byte_sync <= byte_meta;
        end
    end

    // Pulso 'valid' de 1 ciclo en clk cuando llega un byte nuevo
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            spi_byte_valid_clk <= 1'b0;
            spi_byte_clk       <= 8'd0;
        end else begin
            spi_byte_valid_clk <= new_byte_clk;
            if (new_byte_clk)
                spi_byte_clk <= byte_sync;
        end
    end
endmodule
