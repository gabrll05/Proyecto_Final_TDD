// ============================================================
// cpu_armv4.sv  (CPU ARMv4 CON INTERFAZ EXTERNA A LA RAM + PC OUT + FLAGS)
// ============================================================
module cpu_armv4 (
    input  logic clk,
    input  logic reset,

    // interfaz externa para la RAM
    input  logic        ext_we,      // write enable externo
    input  logic [7:0]  ext_addr,    // dirección externa
    input  logic [31:0] ext_wdata,   // dato externo

    output logic [31:0] alu_result_out,
    output logic [3:0]  alu_flags_out, // <- NUEVO: flags de la ALU
    output logic [7:0]  pc_out         // PC hacia fuera
);

    // Señales internas
    logic [31:0] instr;
    logic [31:0] alu_result;
    logic [31:0] regA, regB;
    logic [3:0]  alu_sel;
    logic        reg_wr_en;
    logic [3:0]  reg_rd_a, reg_rd_b, reg_wr;
    logic        pc_en;
    logic [7:0]  pc;

    // RAM interna
    logic [31:0] ram_data_out;
    logic        ram_we_internal;
    logic [7:0]  ram_addr_internal;
    logic [31:0] ram_data_in_internal;

    // Control/muxes
    logic        a_zero_sel, b_imm_sel, wb_sel_mem;
    logic [31:0] imm_ext, alu_A, alu_B, wb_data;

    // branch
    logic        branch_en;
    logic [31:0] branch_imm;

    // ========== PC + ROM ==========
    logic [31:0] next_pc_full;

    always_comb begin
        next_pc_full = {24'd0, pc} + 32'd1;
        if (branch_en)
            next_pc_full = {24'd0, pc} + 32'd1 + branch_imm;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) pc <= 8'd0;
        else if (pc_en) pc <= next_pc_full[7:0];
    end

    // exportamos el PC
    assign pc_out = pc;

    rom_program u_rom (.addr(pc), .data(instr));

    // ========== Control Unit ==========
    control_unit u_ctrl (
        .clk(clk), .reset(reset), .instr(instr),

        .alu_sel(alu_sel), .reg_wr_en(reg_wr_en),
        .reg_rd_a(reg_rd_a), .reg_rd_b(reg_rd_b), .reg_wr(reg_wr),
        .pc_en(pc_en), .ram_we(ram_we_internal),

        .a_zero_sel(a_zero_sel), .b_imm_sel(b_imm_sel), .wb_sel_mem(wb_sel_mem),

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
    assign alu_flags_out  = alu_flags;  // <- NUEVO

    // ========== Writeback ==========
    assign wb_data = wb_sel_mem ? ram_data_out : alu_result;

    // ========== RAM INTERNA con multiplexor para acceso externo ==========
    assign ram_addr_internal    = regA[7:0];
    assign ram_data_in_internal = regB;

    ram_data u_ram (
        .clk(clk),

        .we      (ext_we ? 1'b1      : ram_we_internal),
        .addr    (ext_we ? ext_addr  : ram_addr_internal),
        .data_in (ext_we ? ext_wdata : ram_data_in_internal),

        .data_out(ram_data_out)
    );

endmodule
