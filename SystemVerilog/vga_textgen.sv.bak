// ============================================================
// vga_textgen.sv
// Genera color de salida según los valores de la calculadora
// ============================================================
module vga_textgen (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic visible,
    input  logic [7:0] opA, opB, result,
    input  logic [7:0] operator_ascii,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b
);
    always_comb begin
        if (!visible) begin
            {vga_r, vga_g, vga_b} = 12'h000;  // negro fuera de área visible
        end
        else if (y < 160) begin
            {vga_r, vga_g, vga_b} = 12'h00F;  // zona operandos
        end
        else if (y < 320) begin
            {vga_r, vga_g, vga_b} = 12'h0F0;  // zona operador
        end
        else begin
            {vga_r, vga_g, vga_b} = 12'hF00;  // zona resultado
        end
    end
endmodule
