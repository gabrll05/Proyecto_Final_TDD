// ============================================================
// cpu_armv4.sv
// Procesador ARMv4 mínimo con ROM de programa
// ============================================================

module cpu_armv4 (
    input  logic clk,
    input  logic reset,
    output logic [31:0] alu_result_out
);

    // ============================================================
    // Señales internas
    // ============================================================
    logic [31:0] instr;
    logic [31:0] alu_result;
    logic [31:0] regA, regB;
    logic [3:0]  alu_sel;
    logic        reg_wr_en;
    logic [3:0]  reg_rd_a, reg_rd_b, reg_wr;
    logic        pc_en;
    logic [7:0]  pc;

    // ============================================================
    // PC + ROM
    // ============================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 0;
        else if (pc_en)
            pc <= pc + 1;
    end

    rom_program u_rom (
        .addr(pc),
        .data(instr)
    );

    // ============================================================
    // Unidad de Control
    // ============================================================
    control_unit u_ctrl (
        .clk(clk),
        .reset(reset),
        .instr(instr),
        .alu_sel(alu_sel),
        .reg_wr_en(reg_wr_en),
        .reg_rd_a(reg_rd_a),
        .reg_rd_b(reg_rd_b),
        .reg_wr(reg_wr),
        .pc_en(pc_en)
    );

    // ============================================================
    // Banco de Registros (usa tus nombres reales)
    // ============================================================
    regfile u_regfile (
        .clk(clk),
        .reset(reset),
        .rd_addr_a(reg_rd_a),
        .rd_addr_b(reg_rd_b),
        .rd_data_a(regA),
        .rd_data_b(regB),
        .wr_addr(reg_wr),
        .wr_data(alu_result),
        .wr_en(reg_wr_en)
    );

    // ============================================================
    // ALU (usa tus puertos reales)
    // ============================================================
    alu u_alu (
        .clk(clk),
        .reset(reset),
        .a(regA),
        .b(regB),
        .imm(instr[7:0]),          // soporte inmediato (si lo tienes)
        .instr(instr[24:21]),      // <- CORREGIDO: opcode ARMv4 real
        .sel(alu_sel),
        .result(alu_result),
        .busy(), .z_flag(), .n_flag(), .c_flag(), .v_flag()
    );

    assign alu_result_out = alu_result;

endmodule
