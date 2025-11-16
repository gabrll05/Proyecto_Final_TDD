// ============================================================
// vga_calc_bars.sv
// Dibuja barras horizontales con A, B, SUMA, RESTA, MUL, DIV
// sobre las señales de timing generadas por vga_timing
// ============================================================
module vga_calc_bars (
    input  logic        clk_pix,    // reloj de píxel (25 MHz ideal)
    input  logic        reset,

    // Valores de la calculadora (solo usamos nibble bajo)
    input  logic [3:0]  val_A,
    input  logic [3:0]  val_B,
    input  logic [3:0]  val_SUM,
    input  logic [3:0]  val_RES,
    input  logic [3:0]  val_MUL,
    input  logic [3:0]  val_DIV,

    // Salida VGA
    output logic [3:0]  vga_r,
    output logic [3:0]  vga_g,
    output logic [3:0]  vga_b,
    output logic        vga_hs,
    output logic        vga_vs
);

    // --------------------------------------------------------
    // 1) Timing VGA (usamos tu vga_timing.sv que ya funciona)
    // --------------------------------------------------------
    logic [9:0] x, y;
    logic       video_on;
    logic       line_tick, frame_tick; // no los usamos, pero salen del timing

    vga_timing u_vga_timing (
        .clk_pix   (clk_pix),
        .rst       (reset),
        .x         (x),
        .y         (y),
        .hsync     (vga_hs),
        .vsync     (vga_vs),
        .video_on  (video_on),
        .line_tick (line_tick),
        .frame_tick(frame_tick)
    );

    // --------------------------------------------------------
    // 2) Generador de barras a partir de los valores
    //    Cada barra ocupa ~80 pixeles verticales
    //    y su largo es valor * 32 (máx 15*32 = 480 < 640)
    // --------------------------------------------------------
    logic [9:0] bar_width;
    logic [3:0] r, g, b;

    always_comb begin
        // Fondo negro por defecto
        r = 4'd0;
        g = 4'd0;
        b = 4'd0;

        if (video_on) begin
            // Fondo gris muy oscuro para distinguir que hay señal
            r = 4'd1;
            g = 4'd1;
            b = 4'd1;

            // A: y =   0 ..  79
            if (y < 10'd80) begin
                bar_width = {val_A, 5'd0}; // val_A * 32
                if (x < bar_width) begin
                    r = 4'd0;
                    g = 4'd15; // verde brillante
                    b = 4'd0;
                end
            end
            // B: y =  80 .. 159
            else if (y < 10'd160) begin
                bar_width = {val_B, 5'd0};
                if (x < bar_width) begin
                    r = 4'd0;
                    g = 4'd0;
                    b = 4'd15; // azul
                end
            end
            // SUMA: y = 160 .. 239
            else if (y < 10'd240) begin
                bar_width = {val_SUM, 5'd0};
                if (x < bar_width) begin
                    r = 4'd15; // rojo
                    g = 4'd15; // + verde = amarillo
                    b = 4'd0;
                end
            end
            // RESTA: y = 240 .. 319
            else if (y < 10'd320) begin
                bar_width = {val_RES, 5'd0};
                if (x < bar_width) begin
                    r = 4'd15; // rojo
                    g = 4'd0;
                    b = 4'd15; // magenta
                end
            end
            // MUL: y = 320 .. 399
            else if (y < 10'd400) begin
                bar_width = {val_MUL, 5'd0};
                if (x < bar_width) begin
                    r = 4'd0;
                    g = 4'd15; // verde
                    b = 4'd15; // cyan
                end
            end
            // DIV: y = 400 .. 479
            else if (y < 10'd480) begin
                bar_width = {val_DIV, 5'd0};
                if (x < bar_width) begin
                    r = 4'd15; // blanco (r=g=b)
                    g = 4'd15;
                    b = 4'd15;
                end
            end
        end
    end

    assign vga_r = r;
    assign vga_g = g;
    assign vga_b = b;

endmodule
