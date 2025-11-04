// ============================================================
// control_unit.sv
// Unidad de control del procesador ARMv4 mínimo
// ============================================================

module control_unit (
    input  logic clk,
    input  logic reset,
    input  logic [31:0] instr,
    output logic [3:0]  alu_sel,
    output logic        reg_wr_en,
    output logic [3:0]  reg_rd_a,
    output logic [3:0]  reg_rd_b,
    output logic [3:0]  reg_wr,
    output logic        pc_en,
    output logic        ram_we          // ✅ NUEVO puerto para habilitar escritura en RAM
);

    // ============================================================
    // Extracción de campos de la instrucción
    // ============================================================
    logic [3:0] opcode;
    assign opcode   = instr[24:21];   // bits de operación ARMv4
    assign reg_rd_a = instr[19:16];   // Rn
    assign reg_rd_b = instr[3:0];     // Rm
    assign reg_wr   = instr[15:12];   // Rd

    // ============================================================
    // Máquina de estados
    // ============================================================
    typedef enum logic [1:0] {FETCH, DECODE, EXECUTE, WRITEBACK} state_t;
    state_t state, next_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        unique case (state)
            FETCH:      next_state = DECODE;
            DECODE:     next_state = EXECUTE;
            EXECUTE:    next_state = WRITEBACK;
            WRITEBACK:  next_state = FETCH;
        endcase
    end

    // ============================================================
    // Señales de control según instrucción
    // ============================================================
    always_comb begin
        // Valores por defecto
        alu_sel    = 4'b0000;
        reg_wr_en  = 1'b0;
        pc_en      = 1'b0;
        ram_we     = 1'b0;

        // --------------------------------------------------------
        // Decodificación de operación (opcode)
        // --------------------------------------------------------
        case (opcode)
            4'b1101: alu_sel = 4'b0011;   // MOV
            4'b0100: alu_sel = 4'b0000;   // ADD
            4'b0010: alu_sel = 4'b0001;   // SUB
            4'b1100: alu_sel = 4'b0100;   // STR
            4'b0101: alu_sel = 4'b0101;   // LDR
            4'b1010: alu_sel = 4'b0110;   // B (Branch)
            default: alu_sel = 4'b0000;
        endcase

        // --------------------------------------------------------
        // Control por estado y tipo de instrucción
        // --------------------------------------------------------
        case (state)
            FETCH: begin
                pc_en = 0;
            end

            DECODE: begin
                pc_en = 0;
            end

            EXECUTE: begin
                pc_en = 0;
                // STR -> Escritura a memoria
                if (opcode == 4'b1100)
                    ram_we = 1;
            end

            WRITEBACK: begin
                // LDR, MOV, ADD, SUB escriben en registro
                reg_wr_en = (opcode == 4'b0101 || opcode == 4'b1101 ||
                             opcode == 4'b0100 || opcode == 4'b0010);
                pc_en = 1;
            end
        endcase
    end

endmodule
