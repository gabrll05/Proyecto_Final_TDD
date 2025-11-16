// ============================================================
// vga_textgen.sv
// Muestra 6 barras horizontales con los valores:
// A, B, Suma, Resta, Multiplicación, División
// ============================================================
module vga_textgen (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic       visible,

    input  logic [7:0] opA,
    input  logic [7:0] opB,
    input  logic [7:0] sum_res,
    input  logic [7:0] sub_res,
    input  logic [7:0] mul_res,
    input  logic [7:0] div_res,

    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b
);

    // Escalamos el valor (0–15) a ancho en píxeles (~0–600)
    function automatic logic [9:0] bar_width (input logic [7:0] value);
        logic [15:0] mult;
        begin
            // value (0–15) * 40 -> máx 600
            mult      = value * 16'd40;
            bar_width = mult[9:0];   // nos quedamos con 10 bits
        end
    endfunction

    always_comb begin
        // Fondo negro por defecto
        vga_r = 4'h0;
        vga_g = 4'h0;
        vga_b = 4'h0;

        if (visible) begin
            // Zonas de 80 líneas cada una (480 / 6 = 80)
            if (y < 10'd80) begin
                // A: barra azul
                if (x < bar_width(opA)) begin
                    vga_r = 4'h0;
                    vga_g = 4'h0;
                    vga_b = 4'hF;
                end
            end
            else if (y < 10'd160) begin
                // B: barra verde
                if (x < bar_width(opB)) begin
                    vga_r = 4'h0;
                    vga_g = 4'hF;
                    vga_b = 4'h0;
                end
            end
            else if (y < 10'd240) begin
                // Suma: barra cian
                if (x < bar_width(sum_res)) begin
                    vga_r = 4'h0;
                    vga_g = 4'hF;
                    vga_b = 4'hF;
                end
            end
            else if (y < 10'd320) begin
                // Resta: barra amarilla
                if (x < bar_width(sub_res)) begin
                    vga_r = 4'hF;
                    vga_g = 4'hF;
                    vga_b = 4'h0;
                end
            end
            else if (y < 10'd400) begin
                // Multiplicación: barra magenta
                if (x < bar_width(mul_res)) begin
                    vga_r = 4'hF;
                    vga_g = 4'h0;
                    vga_b = 4'hF;
                end
            end
            else begin
                // División: barra blanca
                if (x < bar_width(div_res)) begin
                    vga_r = 4'hF;
                    vga_g = 4'hF;
                    vga_b = 4'hF;
                end
            end
        end
    end

endmodule
