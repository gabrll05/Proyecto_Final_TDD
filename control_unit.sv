// ============================================================
// control_unit.sv  (a_zero_sel, b_imm_sel, wb_sel_mem + FIX LDR/STR + BRANCH)
// ============================================================

module control_unit (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instr,

    // Control hacia ALU / Regfile / RAM / PC
    output logic [3:0]  alu_sel,
    output logic        reg_wr_en,
    output logic [3:0]  reg_rd_a,   // Rn por defecto; en STR usa Rn (addr)
    output logic [3:0]  reg_rd_b,   // Rm por defecto; en STR se fuerza a Rd (dato)
    output logic [3:0]  reg_wr,     // Rd
    output logic        pc_en,
    output logic        ram_we,

    // Muxes de operandos y de writeback
    output logic        a_zero_sel,   // 1 -> A = 0 (MOVI)
    output logic        b_imm_sel,    // 1 -> B = imm_ext (MOVI)
    output logic        wb_sel_mem,   // 1 -> writeback desde RAM (LDR)

    // --- NUEVO: salto/branch ---
    output logic        branch_en,    // 1 -> usar PC + 1 + branch_imm
    output logic [31:0] branch_imm    // desplazamiento firmado (sign-extend 24b)
);

    // ------------------ Campos ARM-like ------------------
    logic [3:0] Rn, Rd, Rm;
    assign Rn = instr[19:16];
    assign Rd = instr[15:12];
    assign Rm = instr[3:0];

    logic [1:0] cls;       // clase
    logic       bitI;      // inmediato DP/mem
    logic       bitL;      // 1=LDR, 0=STR
    assign cls  = instr[27:26];
    assign bitI = instr[25];
    assign bitL = instr[20];

    // Inmediatos
    logic [7:0]  imm8;
    logic [31:0] imm_ext;
    assign imm8    = instr[7:0];
    assign imm_ext = {24'b0, imm8};

    // --- NUEVO: inmediato de branch (24 bits, firmado) ---
    logic [23:0] imm24;
    assign imm24 = instr[23:0];

    // ------------------ ALU ops ------------------
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

    // ------------------ FSM ------------------
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

    // ------------------ Decodificación ------------------
    logic is_DP, is_MEM, is_BR;
    assign is_DP  = (cls == 2'b00);
    assign is_MEM = (cls == 2'b01);
    assign is_BR  = (instr[27:25] == 3'b101);  // B / BL clase

    logic is_ADD, is_SUB, is_MOVI, is_STR, is_LDR, is_B;
    assign is_ADD  = is_DP  && (instr[24:21] == 4'b0100);
    assign is_SUB  = is_DP  && (instr[24:21] == 4'b0010);
    assign is_MOVI = is_DP  && (instr[24:21] == 4'b1101) && bitI; // MOV #imm
    assign is_STR  = is_MEM && (bitL == 1'b0);
    assign is_LDR  = is_MEM && (bitL == 1'b1);
    assign is_B    = is_BR;  // salto incondicional relativo

    // ------------------ Direcciones de regfile ------------------
    always_comb begin
        reg_rd_a = Rn;
        reg_rd_b = Rm;
        reg_wr   = Rd;
        if (is_STR) begin
            reg_rd_b = Rd; // dato a RAM = Rd
        end
    end

    // ------------------ Señales de control ------------------
    always_comb begin
        // defaults
        alu_sel    = OP_NOP;
        reg_wr_en  = 1'b0;
        pc_en      = 1'b0;
        ram_we     = 1'b0;

        a_zero_sel = 1'b0;
        b_imm_sel  = 1'b0;
        wb_sel_mem = 1'b0;

        branch_en  = 1'b0;
        branch_imm = 32'd0;

        // ALU op
        if (is_ADD)       alu_sel = OP_ADD;
        else if (is_SUB)  alu_sel = OP_SUB;
        else if (is_MOVI) alu_sel = OP_ADD; // MOVI: 0 + imm

        // operandos MOVI
        if (is_MOVI) begin
            a_zero_sel = 1'b1; // A=0
            b_imm_sel  = 1'b1; // B=imm (lo toma el datapath)
        end

        // writeback desde RAM en LDR
        if (is_LDR) begin
            wb_sel_mem = 1'b1;
        end

        unique case (state)
            FETCH: begin end
            DECODE: begin end
            EXECUTE: begin
                if (is_STR) ram_we = 1'b1; // escribir memoria aquí
            end
            WRITEBACK: begin
                // ADD/SUB/MOVI hacen writeback desde ALU,
                // LDR hace writeback desde memoria
                reg_wr_en = (is_ADD | is_SUB | is_MOVI | is_LDR);

                // PC update:
                pc_en = 1'b1; // siempre avanzamos PC en WRITEBACK

                // --- NUEVO: salto relativo ---
                if (is_B) begin
                    branch_en  = 1'b1;
                    // Sign-extend de imm24 (word offset, SIN shift):
                    branch_imm = {{8{imm24[23]}}, imm24};
                    // El PC debe hacer: next_pc = pc + 32'd1 + branch_imm
                end
            end
        endcase
    end

// synthesis translate_off
`ifndef SYNTHESIS
    function automatic string state_name(state_t s);
        case (s)
            FETCH:     return "FETCH";
            DECODE:    return "DECODE";
            EXECUTE:   return "EXECUTE";
            WRITEBACK: return "WRITEBACK";
            default:   return "UNK";
        endcase
    endfunction

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

    // Log solo para simulación
    always_ff @(posedge clk) begin
        if (!reset && next_state == WRITEBACK) begin
            $display(
                "CU@%0t | instr=0x%08h cls=%0b op[24:21]=0x%1h | Rn=%0d Rm=%0d Rd=%0d | wb_en=%0b wb_sel_mem=%0b ram_we=%0b pc_en=%0b a_zero=%0b b_imm=%0b branch_en=%0b branch_imm=%0d | state=%s | alu=%s",
                $time, instr, cls, instr[24:21],
                Rn, Rm, Rd,
                reg_wr_en, wb_sel_mem, ram_we, pc_en, a_zero_sel, b_imm_sel,
                branch_en, branch_imm,
                state_name(next_state), aluop_name(alu_sel)
            );
        end
    end
`endif
// synthesis translate_on

endmodule
