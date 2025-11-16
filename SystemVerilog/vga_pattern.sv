// ============================================================
// vga_pattern.sv
// Genera un patrón de barras de color sencillo
// ============================================================
module vga_pattern (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic       visible,
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b
);
    always_comb begin
        if (!visible) begin
            r = 4'd0;
            g = 4'd0;
            b = 4'd0;
        end else begin
            // Dividimos la pantalla en 8 franjas verticales
            unique case (x[9:7])      // usa los 3 bits más altos de x
                3'b000: begin r=4'hF; g=4'h0; b=4'h0; end // rojo
                3'b001: begin r=4'h0; g=4'hF; b=4'h0; end // verde
                3'b010: begin r=4'h0; g=4'h0; b=4'hF; end // azul
                3'b011: begin r=4'hF; g=4'hF; b=4'h0; end // amarillo
                3'b100: begin r=4'h0; g=4'hF; b=4'hF; end // cian
                3'b101: begin r=4'hF; g=4'h0; b=4'hF; end // magenta
                3'b110: begin r=4'hF; g=4'hF; b=4'hF; end // blanco
                default:begin r=4'h0; g=4'h0; b=4'h0; end // negro
            endcase
        end
    end
endmodule
