// ============================================================
// spi_input_interface.sv
// Reemplazo completo del teclado PS/2 usando SPI (Arduino)
// ============================================================
module spi_input_interface(
    input  logic clk,             // reloj FPGA
    input  logic rst,             // reset global
    input  logic mosi,            // datos del Arduino
    input  logic sck,             // reloj SPI
    input  logic req,             // request (Arduino inicia)
    input  logic ss,              // chip select
    output logic ack,             // acknowledge al Arduino

    output logic [7:0] key_value,   // carácter ASCII del número u operador
    output logic       key_valid,   // pulso 1 ciclo = nueva tecla
    output logic       is_operator  // 1 si es +, -, *, /, =, C
);

    // Señal interna
    logic [3:0] spi_data;

    // ------------------------------------------------------------
    // Instancia del módulo SPI existente (no se modifica)
    // ------------------------------------------------------------
    SPI_io u_spi (
        .rst(rst),
        .mosi(mosi),
        .sck(sck),
        .req(req),
        .ss(ss),
        .ack(ack),
        .master_data_register(spi_data)
    );

    // ------------------------------------------------------------
    // Decodificación de los 4 bits recibidos
    // ------------------------------------------------------------
    always_ff @(posedge sck or negedge rst) begin
        if (!rst) begin
            key_value   <= 8'h00;
            key_valid   <= 0;
            is_operator <= 0;
        end else begin
            // Activa cuando el SPI termina transmisión (ACK=1)
            if (ack) begin
                key_valid   <= 1;
                is_operator <= 0;
                unique case (spi_data)
                    4'h0: key_value <= "0";
                    4'h1: key_value <= "1";
                    4'h2: key_value <= "2";
                    4'h3: key_value <= "3";
                    4'h4: key_value <= "4";
                    4'h5: key_value <= "5";
                    4'h6: key_value <= "6";
                    4'h7: key_value <= "7";
                    4'h8: key_value <= "8";
                    4'h9: key_value <= "9";
                    4'hA: begin key_value <= "+"; is_operator <= 1; end
                    4'hB: begin key_value <= "-"; is_operator <= 1; end
                    4'hC: begin key_value <= "*"; is_operator <= 1; end
                    4'hD: begin key_value <= "/"; is_operator <= 1; end
                    4'hE: begin key_value <= "="; is_operator <= 1; end
                    4'hF: begin key_value <= "C"; is_operator <= 1; end // Clear
                    default: key_value <= "?";
                endcase
            end else begin
                key_valid <= 0;
            end
        end
    end
endmodule
