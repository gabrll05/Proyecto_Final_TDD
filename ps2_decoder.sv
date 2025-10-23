// ============================================================
// ps2_decoder.sv
// Traductor de scancodes PS/2 a valores de calculadora
// ============================================================
module ps2_decoder(
    input  logic        clk,
    input  logic        reset,
    input  logic [7:0]  scancode,   // código desde ps2_controller
    input  logic        valid,      // pulso de tecla nueva
    output logic [7:0]  key_value,  // valor lógico (ASCII o numérico)
    output logic        key_valid,  // 1 = valor listo
    output logic        is_operator // 1 = operador (+,-,*,/,Enter)
);

    logic release_pending; // para ignorar códigos después de F0

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            key_value      <= 8'h00;
            key_valid      <= 0;
            is_operator    <= 0;
            release_pending<= 0;
        end else begin
            key_valid <= 0;

            if (valid) begin
                if (scancode == 8'hF0) begin
                    release_pending <= 1; // siguiente byte es release
                end
                else if (release_pending) begin
                    release_pending <= 0; // ignorar el release
                end
                else begin
                    release_pending <= 0;
                    key_valid   <= 1;
                    is_operator <= 0;

                    unique case (scancode)
                        // Números
                        8'h45: key_value <= "0";
                        8'h16: key_value <= "1";
                        8'h1E: key_value <= "2";
                        8'h26: key_value <= "3";
                        8'h25: key_value <= "4";
                        8'h2E: key_value <= "5";
                        8'h36: key_value <= "6";
                        8'h3D: key_value <= "7";
                        8'h3E: key_value <= "8";
                        8'h46: key_value <= "9";

                        // Operadores
                        8'h79: begin key_value <= "+"; is_operator <= 1; end
                        8'h7B: begin key_value <= "-"; is_operator <= 1; end
                        8'h7C: begin key_value <= "*"; is_operator <= 1; end
                        8'h4A: begin key_value <= "/"; is_operator <= 1; end
                        8'h5A: begin key_value <= "="; is_operator <= 1; end

                        default: begin
                            key_value   <= 8'h00;
                            key_valid   <= 0;
                            is_operator <= 0;
                        end
                    endcase
                end
            end
        end
    end
endmodule
