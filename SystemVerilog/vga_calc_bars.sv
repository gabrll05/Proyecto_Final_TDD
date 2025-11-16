// ============================================================
// vga_calc_bars.sv
// 6 barras verticales con intensidad según A, B, SUM, SUB, MUL, DIV
//  Barra 0: A      (rojo)
//  Barra 1: B      (verde)
//  Barra 2: SUMA   (blanco)
//  Barra 3: RESTA  (cian)
//  Barra 4: MULT   (magenta)
//  Barra 5: DIV    (amarillo)
// ============================================================

module vga_calc_bars (
    input  logic        clk_pix,
    input  logic        rst,         // activo en alto
    input  logic        video_on,
    input  logic [11:0] x,
    input  logic [11:0] y,   // y no lo usamos por ahora

    input  logic [3:0]  A_val,
    input  logic [3:0]  B_val,
    input  logic [3:0]  SUM_val,
    input  logic [3:0]  SUB_val,
    input  logic [3:0]  MUL_val,
    input  logic [3:0]  DIV_val,

    output logic [7:0]  vga_r,
    output logic [7:0]  vga_g,
    output logic [7:0]  vga_b
);
    localparam int H_ACTIVE  = 640;
    localparam int NUM_BARS  = 6;
    localparam int BAR_WIDTH = H_ACTIVE / NUM_BARS;

    logic [7:0] r_next, g_next, b_next;
    logic [3:0] val_sel;
    logic [2:0] bar_index;
    logic [7:0] intensity;

    always_comb begin
        // Valores por defecto para evitar latches
        r_next    = 8'h00;
        g_next    = 8'h00;
        b_next    = 8'h00;
        val_sel   = 4'd0;
        bar_index = 3'd0;
        intensity = 8'd0;

        if (video_on) begin
            // Seleccionar barra según x
            if      (x < BAR_WIDTH*1) bar_index = 3'd0;  // A
            else if (x < BAR_WIDTH*2) bar_index = 3'd1;  // B
            else if (x < BAR_WIDTH*3) bar_index = 3'd2;  // SUMA
            else if (x < BAR_WIDTH*4) bar_index = 3'd3;  // RESTA
            else if (x < BAR_WIDTH*5) bar_index = 3'd4;  // MUL
            else                      bar_index = 3'd5;  // DIV

            // Seleccionar valor de cada barra
            unique case (bar_index)
                3'd0: val_sel = A_val;
                3'd1: val_sel = B_val;
                3'd2: val_sel = SUM_val;
                3'd3: val_sel = SUB_val;
                3'd4: val_sel = MUL_val;
                default: val_sel = DIV_val;
            endcase

            // Mapear nibble (0-15) a intensidad 8 bits (00/11/22/.../FF)
            intensity = {val_sel, val_sel};

            // Colores según barra
            unique case (bar_index)
                3'd0: begin // A: rojo
                    r_next = intensity; g_next = 8'h00;      b_next = 8'h00;
                end
                3'd1: begin // B: verde
                    r_next = 8'h00;      g_next = intensity; b_next = 8'h00;
                end
                3'd2: begin // SUMA: blanco
                    r_next = intensity; g_next = intensity; b_next = intensity;
                end
                3'd3: begin // RESTA: cian
                    r_next = 8'h00;      g_next = intensity; b_next = intensity;
                end
                3'd4: begin // MUL: magenta
                    r_next = intensity; g_next = 8'h00;      b_next = intensity;
                end
                default: begin // DIV: amarillo
                    r_next = intensity; g_next = intensity; b_next = 8'h00;
                end
            endcase
        end
    end

    // Registramos para que la imagen sea estable
    always_ff @(posedge clk_pix) begin
        if (rst) begin
            vga_r <= 8'h00;
            vga_g <= 8'h00;
            vga_b <= 8'h00;
        end else begin
            vga_r <= r_next;
            vga_g <= g_next;
            vga_b <= b_next;
        end
    end

endmodule
