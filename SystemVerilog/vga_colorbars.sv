// ============================================================
// vga_colorbars.sv
// Genera 3 barras verticales estáticas: ROJO | VERDE | AZUL
// ============================================================
module vga_colorbars (
    input  logic        clk_pix,   // reloj de píxel (25 MHz aprox)
    input  logic        rst,       // reset síncrono a clk_pix (activo en alto)
    input  logic        video_on,  // 1 cuando (x,y) está en la zona visible
    input  logic [11:0] x,         // coordenada horizontal
    input  logic [11:0] y,         // coordenada vertical (no la usamos mucho)
    output logic [7:0]  bar_r,
    output logic [7:0]  bar_g,
    output logic [7:0]  bar_b
);

    // Supongamos 640x480, partimos la pantalla en 3 columnas iguales
    localparam int H_ACTIVE   = 640;
    localparam int ONE_THIRD  = H_ACTIVE / 3;
    localparam int TWO_THIRDS = (H_ACTIVE * 2) / 3;

    // Lógica combinacional: decide el color en función de x
    logic [7:0] r_next, g_next, b_next;

    always_comb begin
        if (!video_on) begin
            // Fuera de la zona visible: negro
            r_next = 8'h00;
            g_next = 8'h00;
            b_next = 8'h00;
        end else begin
            // Zona visible: 3 barras verticales
            if (x < ONE_THIRD) begin
                // Barra izquierda: ROJO
                r_next = 8'hFF;
                g_next = 8'h00;
                b_next = 8'h00;
            end else if (x < TWO_THIRDS) begin
                // Barra central: VERDE
                r_next = 8'h00;
                g_next = 8'hFF;
                b_next = 8'h00;
            end else begin
                // Barra derecha: AZUL
                r_next = 8'h00;
                g_next = 8'h00;
                b_next = 8'hFF;
            end
        end
    end

    // Registramos la salida para que sea estable en los pines
    always_ff @(posedge clk_pix) begin
        if (rst) begin
            bar_r <= 8'h00;
            bar_g <= 8'h00;
            bar_b <= 8'h00;
        end else begin
            bar_r <= r_next;
            bar_g <= g_next;
            bar_b <= b_next;
        end
    end

endmodule
