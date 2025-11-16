// ============================================================
// vga_timing.sv
// Genera los tiempos VGA 640x480@60Hz (parámetros genéricos)
// ============================================================

module vga_timing #(
    // Tamaño activo
    parameter int H_ACTIVE = 640,
    parameter int V_ACTIVE = 480,

    // Porch / sync horizontales
    parameter int H_FP  = 16,
    parameter int H_SYNC= 96,
    parameter int H_BP  = 48,

    // Porch / sync verticales
    parameter int V_FP  = 10,
    parameter int V_SYNC= 2,
    parameter int V_BP  = 33,

    // Polaridad HS/VS
    parameter bit HS_POL = 1'b0,
    parameter bit VS_POL = 1'b0
)(
    input  logic        clk_pix,    // reloj de píxel
    input  logic        rst,        // reset activo en alto

    output logic        hsync,
    output logic        vsync,
    output logic        video_on,
    output logic [11:0] x,
    output logic [11:0] y,
    output logic        line_tick,
    output logic        frame_tick
);

    localparam int H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
    localparam int V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;

    // Contadores de píxeles
    always_ff @(posedge clk_pix) begin
        if (rst) begin
            x <= '0;
            y <= '0;
        end else begin
            if (x == H_TOTAL-1) begin
                x <= 12'd0;
                if (y == V_TOTAL-1)
                    y <= 12'd0;
                else
                    y <= y + 12'd1;
            end else begin
                x <= x + 12'd1;
            end
        end
    end

    // Ventanas de sincronización
    wire hsync_window = (x >= (H_ACTIVE + H_FP)) &&
                        (x <  (H_ACTIVE + H_FP + H_SYNC));
    wire vsync_window = (y >= (V_ACTIVE + V_FP)) &&
                        (y <  (V_ACTIVE + V_FP + V_SYNC));

    // Aplicar polaridad
    always_ff @(posedge clk_pix) begin
        if (rst) begin
            hsync <= HS_POL ? 1'b0 : 1'b1;
            vsync <= VS_POL ? 1'b0 : 1'b1;
        end else begin
            hsync <= HS_POL ? hsync_window : ~hsync_window;
            vsync <= VS_POL ? vsync_window : ~vsync_window;
        end
    end

    // Zona visible
    always_ff @(posedge clk_pix) begin
        if (rst)
            video_on <= 1'b0;
        else
            video_on <= (x < H_ACTIVE) && (y < V_ACTIVE);
    end

    assign line_tick  = (x == H_TOTAL-1);
    assign frame_tick = line_tick && (y == V_TOTAL-1);

endmodule
