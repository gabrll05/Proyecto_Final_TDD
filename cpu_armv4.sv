// ============================================================
// cpu_armv4.sv  (añade soporte de MOV#imm, LDR y BRANCH/JUMP)
// ============================================================
module cpu_armv4 (
    input  logic clk,
    input  logic reset,
    output logic [31:0] alu_result_out
);

    // Señales
    logic [31:0] instr;
    logic [31:0] alu_result;
    logic [31:0] regA, regB;
    logic [3:0]  alu_sel;
    logic        reg_wr_en;
    logic [3:0]  reg_rd_a, reg_rd_b, reg_wr;
    logic        pc_en;
    logic [7:0]  pc;

    // RAM
    logic [31:0] ram_data_out;
    logic        ram_we;
    logic [7:0]  ram_addr;
    logic [31:0] ram_data_in;

    // Control/muxes
    logic        a_zero_sel, b_imm_sel, wb_sel_mem;
    logic [31:0] imm_ext, alu_A, alu_B, wb_data;

    // --- NUEVO: señales de branch desde la CU ---
    logic        branch_en;
    logic [31:0] branch_imm;

    // ========== PC + ROM ==========
    // next_pc en 32 bits para sumar con branch_imm y luego truncar a 8 bits
    logic [31:0] next_pc_full;

    always_comb begin
        next_pc_full = {24'd0, pc} + 32'd1;          // avance secuencial
        if (branch_en) begin
            next_pc_full = {24'd0, pc} + 32'd1 + branch_imm;  // salto relativo firmado
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)      pc <= 8'd0;
        else if (pc_en) pc <= next_pc_full[7:0];     // ROM de 256 palabras
    end

    rom_program u_rom (.addr(pc), .data(instr));

    // ========== Unidad de Control ==========
    control_unit u_ctrl (
        .clk(clk), .reset(reset), .instr(instr),

        .alu_sel(alu_sel), .reg_wr_en(reg_wr_en),
        .reg_rd_a(reg_rd_a), .reg_rd_b(reg_rd_b), .reg_wr(reg_wr),
        .pc_en(pc_en), .ram_we(ram_we),

        .a_zero_sel(a_zero_sel), .b_imm_sel(b_imm_sel), .wb_sel_mem(wb_sel_mem),

        // --- NUEVO: branch ---
        .branch_en(branch_en), .branch_imm(branch_imm)
    );

    // ========== Banco de registros ==========
    regfile u_regfile (
        .clk(clk), .reset(reset),
        .rd_addr_a(reg_rd_a), .rd_addr_b(reg_rd_b),
        .rd_data_a(regA), .rd_data_b(regB),
        .wr_addr(reg_wr),
        .wr_data(wb_data),
        .wr_en(reg_wr_en)
    );

    // ========== ALU ==========
    // MOVI: B toma imm_ext y A es 0
    assign imm_ext = {24'b0, instr[7:0]};
    assign alu_A   = a_zero_sel ? 32'd0 : regA;
    assign alu_B   = b_imm_sel  ? imm_ext : regB;

    logic [3:0] alu_flags;
    alu_core #(.N(32)) u_alu_core (
        .clk(clk), .reset(reset),
        .A(alu_A), .B(alu_B), .CIN_BIN(1'b0),
        .OP(alu_sel), .Y(alu_result), .FLAGS(alu_flags)
    );
    assign alu_result_out = alu_result;

    // ========== Writeback ==========
    // LDR: wb_sel_mem=1 -> desde RAM; caso contrario desde ALU
    assign wb_data = wb_sel_mem ? ram_data_out : alu_result;

    // ========== RAM de datos ==========
    // Dirección = Rn (regA); Dato = puerto B del regfile.
    // En STR, la CU fuerza reg_rd_b = Rd, así que regB contiene el dato a escribir.
    assign ram_addr    = regA[7:0];
    assign ram_data_in = regB;

    ram_data u_ram (
        .clk(clk), .we(ram_we),
        .addr(ram_addr),
        .data_in(ram_data_in),
        .data_out(ram_data_out)
    );

endmodule
