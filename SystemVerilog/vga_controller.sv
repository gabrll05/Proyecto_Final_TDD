module vga_controller (
    input  logic clk_25MHz,       // reloj de píxel
    input  logic reset,
    output logic [9:0] x,         // coordenada horizontal
    output logic [9:0] y,         // coordenada vertical
    output logic hsync, vsync,
    output logic visible          // 1 cuando (x,y) está dentro de pantalla
);

    // Parámetros VGA 640x480 @60Hz
    parameter H_VISIBLE = 640;
    parameter H_FRONT   = 16;
    parameter H_SYNC    = 96;
    parameter H_BACK    = 48;
    parameter H_TOTAL   = 800;

    parameter V_VISIBLE = 480;
    parameter V_FRONT   = 10;
    parameter V_SYNC    = 2;
    parameter V_BACK    = 33;
    parameter V_TOTAL   = 525;

    // Contadores horizontales y verticales
    always_ff @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            x <= 0;
            y <= 0;
        end else begin
            if (x == H_TOTAL - 1) begin
                x <= 0;
                if (y == V_TOTAL - 1)
                    y <= 0;
                else
                    y <= y + 1;
            end else begin
                x <= x + 1;
            end
        end
    end

    // Sincronización H y V
    assign hsync   = ~((x >= (H_VISIBLE + H_FRONT)) && (x < (H_VISIBLE + H_FRONT + H_SYNC)));
    assign vsync   = ~((y >= (V_VISIBLE + V_FRONT)) && (y < (V_VISIBLE + V_FRONT + V_SYNC)));

    // Zona visible
    assign visible = (x < H_VISIBLE) && (y < V_VISIBLE);

endmodule
