// ============================================================
// control_unit.sv
// Unidad de Control para CPU ARMv4 mínima
// ============================================================
module control_unit(
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instr,       // instrucción desde ROM
    input  logic        alu_busy,    // indica si la ALU está ocupada (división)
    output logic [3:0]  alu_sel,     // operación ALU
    output logic        reg_wr_en,   // habilita escritura
    output logic [2:0]  reg_rd_a,    // dirección reg A
    output logic [2:0]  reg_rd_b,    // dirección reg B
    output logic [2:0]  reg_wr,      // dirección reg destino
    output logic        pc_en        // incremento del PC
);

    // Estados del ciclo
    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        WRITEBACK
    } state_t;

    state_t state, next_state;

    // Campos de la instrucción
    logic [3:0] opcode;
    logic [2:0] rd, rn, rm;

    // Separar campos de la instrucción (formato simple)
    always_comb begin
        opcode = instr[31:28];
        rd     = instr[27:25];
        rn     = instr[24:22];
        rm     = instr[21:19];
    end

    // Transición de estados
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    // FSM principal
    always_comb begin
        // valores por defecto
        next_state = state;
        reg_wr_en  = 0;
        pc_en      = 0;
        alu_sel    = 4'b0000;

        case (state)
            FETCH: begin
                next_state = DECODE;
            end

            DECODE: begin
                // decodificar opcode
                next_state = EXECUTE;
                case (opcode)
                    4'b0000: alu_sel = 4'b0000; // ADD
                    4'b0001: alu_sel = 4'b0001; // SUB
                    4'b0010: alu_sel = 4'b0010; // MUL
                    4'b0011: alu_sel = 4'b0011; // MOV
                    4'b0100: alu_sel = 4'b0100; // CMP
                    4'b0101: alu_sel = 4'b0101; // DIV
                    default: alu_sel = 4'b0000;
                endcase
            end

            EXECUTE: begin
                if (alu_busy)
                    next_state = EXECUTE; // espera si división no ha terminado
                else
                    next_state = WRITEBACK;
            end

            WRITEBACK: begin
                reg_wr_en = 1;
                pc_en     = 1;
                next_state = FETCH;
            end
        endcase
    end

endmodule
