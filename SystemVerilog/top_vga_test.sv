// ============================================================
// top_vga_test.sv
// Top mínimo para probar VGA con barras R/G/B estáticas
// ============================================================
module top_vga_test (
    input  logic        CLOCK_50,   // reloj de 50 MHz de la DE10
    input  logic        RESET_N,    // reset global activo en bajo (KEY[0])

    output logic        VGA_HS,
    output logic        VGA_VS,
    output logic [7:0]  VGA_R,
    output logic [7:0]  VGA_G,
    output logic [7:0]  VGA_B,
    output logic        VGA_CLK,
    output logic        VGA_BLANK_N,
    output logic        VGA_SYNC_N
);

    // --------------------------------------------------------
    // Generar clk_pix ~25 MHz a partir de CLOCK_50 (toggle)
    // --------------------------------------------------------
    logic clk_pix;

    always_ff @(posedge CLOCK_50 or negedge RESET_N) begin
        if (!RESET_N)
            clk_pix <= 1'b0;
        else
            clk_pix <= ~clk_pix;   // divide por 2 → ~25 MHz
    end

    assign VGA_CLK     = clk_pix;
    assign VGA_BLANK_N = 1'b1;    // siempre activo (video habilitado)
    assign VGA_SYNC_N  = 1'b0;    // normalmente 0 en DE10

    // --------------------------------------------------------
    // Sincronizar RESET al dominio de clk_pix
    // --------------------------------------------------------
    logic r1, r2;
    always_ff @(posedge clk_pix or negedge RESET_N) begin
        if (!RESET_N) begin
            r1 <= 1'b1;
            r2 <= 1'b1;
        end else begin
            r1 <= 1'b0;
            r2 <= r1;
        end
    end
    wire rst_pix = r2;  // reset activo en alto, sincronizado a clk_pix

    // --------------------------------------------------------
    // Señales del controlador VGA (timing 640x480@60Hz)
    // --------------------------------------------------------
    logic        hs_int, vs_int;
    logic        video_on;
    logic [11:0] x, y;
    logic [7:0]  dummy_r, dummy_g, dummy_b;  // salidas internas no usadas

    vga_controller #(
        .H_ACTIVE(640), .V_ACTIVE(480),
        .H_FP(16), .H_SYNC(96), .H_BP(48),
        .V_FP(10), .V_SYNC(2),  .V_BP(33),
        .HS_POL(1'b0), .VS_POL(1'b0),
        .N_COLOR_BITS(8),
        .USE_TEST_PATTERN(1'b0)   // usamos nuestro propio generador de color
    ) u_vga (
        .clk_pix (clk_pix),
        .rst     (rst_pix),

        .rgb_in_r(8'd0),  // ignorados porque USE_TEST_PATTERN=0 y usamos
        .rgb_in_g(8'd0),  // nuestro módulo vga_colorbars para el color final
        .rgb_in_b(8'd0),

        .hsync   (hs_int),
        .vsync   (vs_int),
        .vga_r   (dummy_r),
        .vga_g   (dummy_g),
        .vga_b   (dummy_b),

        .video_on(video_on),
        .x       (x),
        .y       (y)
    );

    // Sacar HS/VS a los pines (registrados)
    always_ff @(posedge clk_pix or negedge RESET_N) begin
        if (!RESET_N) begin
            VGA_HS <= 1'b1;
            VGA_VS <= 1'b1;
        end else begin
            VGA_HS <= hs_int;
            VGA_VS <= vs_int;
        end
    end

    // --------------------------------------------------------
    // Generador de barras estáticas R/G/B
    // --------------------------------------------------------
    logic [7:0] bar_r, bar_g, bar_b;

    vga_colorbars u_colorbars (
        .clk_pix(clk_pix),
        .rst    (rst_pix),
        .video_on(video_on),
        .x      (x),
        .y      (y),
        .bar_r  (bar_r),
        .bar_g  (bar_g),
        .bar_b  (bar_b)
    );

    // Registrar colores hacia los pines VGA
    always_ff @(posedge clk_pix or negedge RESET_N) begin
        if (!RESET_N) begin
            VGA_R <= 8'h00;
            VGA_G <= 8'h00;
            VGA_B <= 8'h00;
        end else begin
            VGA_R <= bar_r;
            VGA_G <= bar_g;
            VGA_B <= bar_b;
        end
    end

endmodule
