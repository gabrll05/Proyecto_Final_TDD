// ============================================================
// ps2_controller.sv  (versión final)
// ============================================================
module ps2_controller(
    input  logic clk,        // reloj principal (50 MHz)
    input  logic reset,
    input  logic ps2_clk,
    input  logic ps2_data,
    output logic [7:0] scancode,
    output logic       valid
);

    // --- Sincronización a clk de FPGA ---
    logic [2:0] ps2_clk_sync;
    logic [2:0] ps2_data_sync;

    always_ff @(posedge clk) begin
        ps2_clk_sync  <= {ps2_clk_sync[1:0], ps2_clk};
        ps2_data_sync <= {ps2_data_sync[1:0], ps2_data};
    end

    // --- Detección de flanco de bajada del reloj PS/2 ---
    wire ps2_clk_fall = (ps2_clk_sync[2:1] == 2'b10);

    // --- Variables internas ---
    logic [10:0] shift_reg;
    logic [3:0]  bit_count;
    logic        reading;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 11'b0;
            bit_count <= 0;
            reading   <= 0;
            valid     <= 0;
            scancode  <= 8'b0;
        end 
        else begin
            valid <= 0;

            // detectar bit de inicio
            if (!reading && ps2_data_sync[2] == 0)
                reading <= 1;

            if (reading && ps2_clk_fall) begin
                shift_reg[bit_count] <= ps2_data_sync[2];
                bit_count <= bit_count + 1;

                if (bit_count == 10) begin
                    reading   <= 0;
                    bit_count <= 0;
                    scancode  <= shift_reg[8:1]; // bits de datos
                    valid     <= 1;
                end
            end
        end
    end
endmodule
