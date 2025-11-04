// ============================================================
// cpu_armv4.sv
// Procesador ARMv4 mínimo con ROM y RAM de datos
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
    // PC + ROM (Programa)
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
    // Banco de Registros
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
    // ALU
    // ============================================================
    alu u_alu (
        .clk(clk),
        .reset(reset),
        .a(regA),
        .b(regB),
        .imm(instr[7:0]),          // Soporte inmediato (MOV)
        .instr(instr[24:21]),      // Opcode ARMv4
        .sel(alu_sel),
        .result(alu_result),
        .busy(), .z_flag(), .n_flag(), .c_flag(), .v_flag()
    );

    assign alu_result_out = alu_result;

    // ============================================================
    // Memoria de Datos (para instrucciones STR / LDR)
    // ============================================================
    logic [31:0] ram_data_out;
    logic        ram_wr_en;
    logic        ram_rd_en;

    // STR → opcode 1100 | LDR → opcode 0101 (solo ejemplo)
    assign ram_wr_en = (instr[24:21] == 4'b1100);
    assign ram_rd_en = (instr[24:21] == 4'b0101);

    ram_data u_ram (
        .clk(clk),
        .wr_en(ram_wr_en),
        .addr(regA),
        .wr_data(regB),
        .rd_data(ram_data_out)
    );

    // Si se ejecuta un LDR, cargar el valor desde memoria
    always_ff @(posedge clk) begin
        if (ram_rd_en)
            $display("📥 LOAD: R%0d <= MEM[%0d] = %0d (0x%0h) @t=%0t",
                     reg_wr, regA, ram_data_out, ram_data_out, $time);
    end

endmodule
