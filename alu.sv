// ============================================================
// alu.sv
// Unidad Aritmético-Lógica (ALU) para CPU ARMv4 mínima
// Versión con división secuencial integrada
// ============================================================

module alu (
    input  logic        clk,        // reloj del sistema
    input  logic        reset,      // reset sincrónico
    input  logic [31:0] a,          // operando A
    input  logic [31:0] b,          // operando B
    input  logic [3:0]  sel,        // código de operación
    output logic [31:0] result,     // resultado
    output logic        z_flag,     // flag de cero
    output logic        n_flag,     // flag de negativo
    output logic        c_flag,     // flag de acarreo
    output logic        v_flag,     // flag de overflow
    output logic        busy        // indica si la división está en progreso
);

    // Señales internas
    logic [32:0] temp;
    logic [31:0] div_q, div_r;
    logic div_done, div_start;

    // Instancia del divisor secuencial
    divider u_divider (
        .clk       (clk),
        .reset     (reset),
        .start     (div_start),
        .dividend  (a),
        .divisor   (b),
        .quotient  (div_q),
        .remainder (div_r),
        .done      (div_done)
    );

    // Señal de control de inicio para la división
    always_comb begin
        // Valores por defecto
        result     = 32'b0;
        temp       = 33'b0;
        c_flag     = 1'b0;
        v_flag     = 1'b0;
        div_start  = 1'b0;
        busy       = 1'b0;

        case (sel)
            // ====================================================
            // 0000: ADD
            // ====================================================
            4'b0000: begin
                temp   = a + b;
                result = temp[31:0];
                c_flag = temp[32];
                v_flag = (a[31] == b[31]) && (result[31] != a[31]);
            end

            // ====================================================
            // 0001: SUB
            // ====================================================
            4'b0001: begin
                temp   = a - b;
                result = temp[31:0];
                c_flag = ~temp[32];
                v_flag = (a[31] != b[31]) && (result[31] != a[31]);
            end

            // ====================================================
            // 0010: MUL
            // ====================================================
            4'b0010: result = a * b;

            // ====================================================
            // 0011: MOV (paso directo)
            // ====================================================
            4'b0011: result = b;

            // ====================================================
            // 0100: CMP (solo actualiza flags)
            // ====================================================
            4'b0100: begin
                temp   = a - b;
                result = 32'b0;
                c_flag = ~temp[32];
                v_flag = (a[31] != b[31]) && (temp[31] != a[31]);
            end

            // ====================================================
            // 0101: DIV (módulo secuencial)
            // ====================================================
            4'b0101: begin
                div_start = 1'b1;
                if (div_done) begin
                    result = div_q;
                    busy   = 1'b0;
                end else begin
                    busy   = 1'b1;      // división en progreso
                    result = 32'hDEAD_BEEF; // valor temporal
                end
            end

            default: result = 32'b0;
        endcase
    end

    // ============================================================
    // Flags comunes
    // ============================================================
    assign z_flag = (result == 32'b0);
    assign n_flag = result[31];

endmodule
