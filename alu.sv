// ============================================================
// alu.sv
// Unidad Aritmético-Lógica (ALU) con soporte inmediato y debug
// ============================================================

module alu (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] a,          // operando A (desde regfile)
    input  logic [31:0] b,          // operando B (desde regfile)
    input  logic [7:0]  imm,        // operando inmediato (desde instr[7:0])
    input  logic [3:0]  instr,      // opcode (desde instr[24:21])
    input  logic [3:0]  sel,        // selección desde la unidad de control
    output logic [31:0] result,     // salida del resultado
    output logic        busy,       // bandera (para DIV)
    output logic        z_flag, n_flag, c_flag, v_flag
);

    // Señales internas
    logic [31:0] res_next;

    // ============================================================
    // Lógica combinacional principal
    // ============================================================
    always_comb begin
        busy   = 0;
        z_flag = 0;
        n_flag = 0;
        c_flag = 0;
        v_flag = 0;

        case (instr)
            4'b0100: res_next = a + b;            // ADD
            4'b0010: res_next = a - b;            // SUB
            4'b0011: res_next = a * b;            // MUL (no ARM real, solo ejemplo)
            4'b1101: res_next = {24'b0, imm};     // MOV inmediato ✅
            4'b0101: begin                        // CMP (setea Z)
                res_next = (a == b) ? 32'd1 : 32'd0;
                z_flag   = (a == b);
            end
            4'b0110: begin                        // DIV simple
                if (b != 0) begin
                    res_next = a / b;
                    busy = 0;
                end else begin
                    res_next = 32'd0;
                end
            end
            default: res_next = 32'd0;            // NOP
        endcase
    end

    // ============================================================
    // Registro del resultado (sincrónico)
    // ============================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            result <= 32'b0;
        else
            result <= res_next;
    end

    // ============================================================
    // Mensajes de depuración (opcional)
    // ============================================================
    always_ff @(posedge clk) begin
        if (!reset) begin
            case (instr)
                4'b0100: $display("🧮 ALU: ADD %0d + %0d = %0d @t=%0t", a, b, res_next, $time);
                4'b0010: $display("➖ ALU: SUB %0d - %0d = %0d @t=%0t", a, b, res_next, $time);
                4'b0011: $display("✖️  ALU: MUL %0d * %0d = %0d @t=%0t", a, b, res_next, $time);
                4'b1101: $display("📥 ALU: MOV #%0d → result=%0d @t=%0t", imm, res_next, $time);
                4'b0101: $display("⚖️  ALU: CMP %0d vs %0d → Z=%b @t=%0t", a, b, z_flag, $time);
                4'b0110: $display("➗ ALU: DIV %0d / %0d = %0d @t=%0t", a, b, res_next, $time);
                default: $display("⏸️  ALU: NOP/UNKNOWN opcode=%b @t=%0t", instr, $time);
            endcase
        end
    end

endmodule
