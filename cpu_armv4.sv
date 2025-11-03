// ============================================================
// cpu_armv4.sv
// CPU mínima ARMv4 (ALU + RegFile + Control + ROM + RAM)
// Con salida del resultado de la ALU hacia el top FPGA
// ============================================================
module cpu_armv4(
    input  logic clk,
    input  logic reset,
    output logic [31:0] alu_result_out   // nueva salida: resultado de la ALU
);

    // Señales internas
    logic [31:0] instr;
    logic [31:0] alu_result;
    logic [31:0] reg_a, reg_b;
    logic [3:0]  alu_sel;
    logic [2:0]  reg_rd_a, reg_rd_b, reg_wr;
    logic        reg_wr_en, alu_busy, pc_en;

    // =========================================
    // Contador de programa (PC)
    // =========================================
    logic [7:0] pc;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 0;
        else if (pc_en)
            pc <= pc + 1;
    end

    // =========================================
    // Memoria de programa (ROM)
    // =========================================
    rom_program u_rom (
        .addr(pc),
        .data(instr)
    );

    // =========================================
    // Banco de registros
    // =========================================
    regfile u_regfile (
        .clk(clk),
        .reset(reset),
        .rd_addr_a(reg_rd_a),
        .rd_addr_b(reg_rd_b),
        .rd_data_a(reg_a),
        .rd_data_b(reg_b),
        .wr_addr(reg_wr),
        .wr_data(alu_result),
        .wr_en(reg_wr_en)
    );

    // =========================================
    // ALU
    // =========================================
    alu u_alu (
        .clk(clk),
        .reset(reset),
        .a(reg_a),
        .b(reg_b),
        .sel(alu_sel),
        .result(alu_result),
        .busy(alu_busy),
        .z_flag(),
        .n_flag(),
        .c_flag(),
        .v_flag()
    );

    // =========================================
    // Unidad de control
    // =========================================
    control_unit u_ctrl (
        .clk(clk),
        .reset(reset),
        .instr(instr),
        .alu_busy(alu_busy),
        .alu_sel(alu_sel),
        .reg_wr_en(reg_wr_en),
        .reg_rd_a(reg_rd_a),
        .reg_rd_b(reg_rd_b),
        .reg_wr(reg_wr),
        .pc_en(pc_en)
    );

    // =========================================
    // Salida para debug y visualización en FPGA
    // =========================================
    assign alu_result_out = alu_result;

endmodule
