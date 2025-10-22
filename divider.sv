// ============================================================
// divider.sv
// Módulo de división entera sin signo (iterativo)
// ============================================================

module divider (
    input  logic        clk,        // reloj
    input  logic        reset,      // reset síncrono
    input  logic        start,      // señal de inicio
    input  logic [31:0] dividend,   // numerador (a)
    input  logic [31:0] divisor,    // denominador (b)
    output logic [31:0] quotient,   // resultado
    output logic [31:0] remainder,  // residuo
    output logic        done        // operación terminada
);

    // Estados internos
    typedef enum logic [1:0] {
        IDLE,
        RUNNING,
        DONE
    } state_t;

    state_t state;
    logic [63:0] temp_dividend;
    logic [31:0] temp_divisor;
    logic [5:0]  count;  // 0–31

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= IDLE;
            quotient      <= 0;
            remainder     <= 0;
            temp_dividend <= 0;
            temp_divisor  <= 0;
            count         <= 0;
            done          <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start && divisor != 0) begin
                        temp_dividend <= {32'b0, dividend};
                        temp_divisor  <= divisor;
                        quotient      <= 0;
                        count         <= 32;
                        state         <= RUNNING;
                    end
                end

                RUNNING: begin
                    if (count > 0) begin
                        temp_dividend = temp_dividend << 1;
                        quotient = quotient << 1;

                        if (temp_dividend[63:32] >= temp_divisor) begin
                            temp_dividend[63:32] = temp_dividend[63:32] - temp_divisor;
                            quotient[0] = 1;
                        end

                        count <= count - 1;
                    end else begin
                        remainder <= temp_dividend[63:32];
                        state     <= DONE;
                    end
                end

                DONE: begin
                    done  <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
