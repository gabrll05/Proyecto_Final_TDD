// ============================================================
// clock_divider.sv
// Divisor de reloj simple (reduce frecuencia para visualización)
// ============================================================
module clock_divider(
    input  logic clk_in,     // reloj de entrada (CLOCK_50)
    input  logic rst_n,      // reset activo en bajo
    output logic clk_out     // reloj dividido (~1 Hz)
);
    logic [25:0] counter;

    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            counter <= counter + 1;
            clk_out <= counter[25];   // divide entre ~33 millones
        end
    end
endmodule
