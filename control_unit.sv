// ============================================================
// control_unit.sv  (con a_zero_sel, b_imm_sel, wb_sel_mem + DEBUG)
// ============================================================

module control_unit (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instr,

    // Control hacia ALU / Regfile / RAM / PC
    output logic [3:0]  alu_sel,
    output logic        reg_wr_en,
    output logic [3:0]  reg_rd_a,
    output logic [3:0]  reg_rd_b,
    output logic [3:0]  reg_wr,
    output logic        pc_en,
    output logic        ram_we,

    // NUEVOS: muxes de operandos y de writeback
    output logic        a_zero_sel,   // 1 -> A = 0
    output logic        b_imm_sel,    // 1 -> B = imm_ext
    output logic        wb_sel_mem    // 1 -> writeback desde RAM
);

    // ============================================================
    // Extracción de campos de la instrucción (formato mínimo usado)
    // ============================================================
    logic [3:0] opcode;
    assign opcode   = instr[24:21];   // opcode reducido
    assign reg_rd_a = instr[19:16];   // Rn
    assign reg_rd_b = instr[3:0];     // Rm
    assign reg_wr   = instr[15:12];   // Rd

    // Inmediato (como lo usa tu CPU)
    logic [7:0]  imm8;
    logic [31:0] imm_ext;
    assign imm8    = instr[7:0];
    assign imm_ext = {24'b0, imm8};

    // ============================================================
    // Códigos de operación para la ALU (igual que alu_core)
    // ============================================================
    localparam logic [3:0]
        OP_NOP = 4'd0,
        OP_ADD = 4'd1,
        OP_SUB = 4'd2,
        OP_MUL = 4'd3,
        OP_DIV = 4'd4,
        OP_MOD = 4'd5,
        OP_AND = 4'd6,
        OP_OR  = 4'd7,
        OP_XOR = 4'd8,
        OP_SLL = 4'd9,
        OP_SRL = 4'd10;

    // ============================================================
    // Estados
    // ============================================================
    typedef enum logic [1:0] {FETCH, DECODE, EXECUTE, WRITEBACK} state_t;
    state_t state, next_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= FETCH;
        else       state <= next_state;
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

    // Clasificación de instrucciones (según los códigos que usas)
    logic is_ADD, is_SUB, is_MOVI, is_STR, is_LDR, is_B;
    always_comb begin
        is_ADD  = (opcode == 4'b0100);
        is_SUB  = (opcode == 4'b0010);
        is_MOVI = (opcode == 4'b1101); // MOV #imm
        is_STR  = (opcode == 4'b1100);
        is_LDR  = (opcode == 4'b0101);
        is_B    = (opcode == 4'b1010);
    end

    // ============================================================
    // Señales de control por defecto + decodificación
    // ============================================================
    always_comb begin
        // Defaults
        alu_sel    = OP_NOP;
        reg_wr_en  = 1'b0;
        pc_en      = 1'b0;
        ram_we     = 1'b0;

        a_zero_sel = 1'b0;
        b_imm_sel  = 1'b0;
        wb_sel_mem = 1'b0;

        // Selección de operación ALU (independiente del estado)
        if (is_ADD)       alu_sel = OP_ADD;
        else if (is_SUB)  alu_sel = OP_SUB;
        else if (is_MOVI) alu_sel = OP_ADD; // 0 + imm

        // MOV #imm: operandos especiales
        if (is_MOVI) begin
            a_zero_sel = 1'b1; // A=0
            b_imm_sel  = 1'b1; // B=imm
        end

        // LDR: writeback desde memoria
        if (is_LDR) begin
            wb_sel_mem = 1'b1;
        end

        // Control dependiente del estado
        unique case (state)
            FETCH: begin
                // nada especial
            end

            DECODE: begin
                // típicamente nada, ya decodificamos arriba
            end

            EXECUTE: begin
                // STR escribe a memoria en este “ciclo”
                if (is_STR)
                    ram_we = 1'b1;
            end

            WRITEBACK: begin
                // Writeback para ADD/SUB/MOVI/LDR
                reg_wr_en = (is_ADD | is_SUB | is_MOVI | is_LDR);
                pc_en     = 1'b1; // incremento del PC (secuencial)
            end
        endcase
    end

`ifndef SYNTHESIS
    // ================== DEBUG / PRINTS (solo simulación) ==================
    // Función: nombre del estado
    function automatic string state_name(state_t s);
        case (s)
            FETCH:     return "FETCH";
            DECODE:    return "DECODE";
            EXECUTE:   return "EXECUTE";
            WRITEBACK: return "WRITEBACK";
            default:   return "UNK";
        endcase
    endfunction

    // Función: mnemónico de instrucción (a partir de opcode)
    function automatic string instr_name(logic [3:0] op);
        case (op)
            4'b0100: return "ADD";
            4'b0010: return "SUB";
            4'b1101: return "MOVI";
            4'b1100: return "STR";
            4'b0101: return "LDR";
            4'b1010: return "B";
            default: return "UNK";
        endcase
    endfunction

    // Función: nombre del alu_sel
    function automatic string aluop_name(logic [3:0] op);
        case (op)
            OP_NOP: return "NOP";
            OP_ADD: return "ADD";
            OP_SUB: return "SUB";
            OP_MUL: return "MUL";
            OP_DIV: return "DIV";
            OP_MOD: return "MOD";
            OP_AND: return "AND";
            OP_OR : return "OR";
            OP_XOR: return "XOR";
            OP_SLL: return "SLL";
            OP_SRL: return "SRL";
            default: return "UNK";
        endcase
    endfunction

    // Imprime UNA línea por instrucción al entrar a WRITEBACK
    // (momento en que se decide writeback/pc_en/ram_we etc.)
    always_ff @(posedge clk) begin
        if (!reset && next_state == WRITEBACK) begin
            $display(
                "CU@%0t | instr=0x%08h opcode=0x%1h(%s) | alu_sel=%s | Rn=%0d Rm=%0d Rd=%0d | imm8=%0d(0x%02h) imm_ext=%0d | ctrl: wb_en=%0b wb_sel_mem=%0b ram_we=%0b pc_en=%0b a_zero=%0b b_imm=%0b | state=%s",
                $time, instr, opcode, instr_name(opcode), aluop_name(alu_sel),
                reg_rd_a, reg_rd_b, reg_wr,
                imm8, imm8, imm_ext,
                reg_wr_en, wb_sel_mem, ram_we, pc_en, a_zero_sel, b_imm_sel,
                state_name(next_state)
            );
        end
    end
`endif

endmodule
