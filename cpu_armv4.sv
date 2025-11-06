// ============================================================
// cpu_armv4.sv  (añade MUXes para MOV#imm y LDR)
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

    // Líneas de control/mux
    logic        a_zero_sel, b_imm_sel, wb_sel_mem;
    logic [31:0] imm_ext, alu_A, alu_B, wb_data;

    // PC + ROM
    always_ff @(posedge clk or posedge reset) begin
        if (reset)      pc <= 8'd0;
        else if (pc_en) pc <= pc + 8'd1;
    end

    rom_program u_rom (.addr(pc), .data(instr));

    // Unidad de Control (ya con nuevas salidas)
    control_unit u_ctrl (
        .clk(clk), .reset(reset), .instr(instr),
        .alu_sel(alu_sel), .reg_wr_en(reg_wr_en),
        .reg_rd_a(reg_rd_a), .reg_rd_b(reg_rd_b), .reg_wr(reg_wr),
        .pc_en(pc_en), .ram_we(ram_we),
        .a_zero_sel(a_zero_sel), .b_imm_sel(b_imm_sel), .wb_sel_mem(wb_sel_mem)
    );

    // Banco de registros
    regfile u_regfile (
        .clk(clk), .reset(reset),
        .rd_addr_a(reg_rd_a), .rd_addr_b(reg_rd_b),
        .rd_data_a(regA), .rd_data_b(regB),
        .wr_addr(reg_wr),
        .wr_data(wb_data),
        .wr_en(reg_wr_en)
    );

    // --- MUX de operandos para la ALU ---
    assign imm_ext = {24'b0, instr[7:0]};
    assign alu_A   = a_zero_sel ? 32'd0 : regA;
    assign alu_B   = b_imm_sel  ? imm_ext : regB;

    // ALU core
    logic [3:0] alu_flags;
    alu_core #(.N(32)) u_alu_core (
        .clk(clk), .reset(reset),
        .A(alu_A), .B(alu_B), .CIN_BIN(1'b0),
        .OP(alu_sel), .Y(alu_result), .FLAGS(alu_flags)
    );
    assign alu_result_out = alu_result;

    // --- MUX de writeback: ALU vs RAM ---
    assign wb_data = wb_sel_mem ? ram_data_out : alu_result;

    // RAM de datos
    assign ram_addr    = regA[7:0]; // dirección = Rn (8 bits)
    assign ram_data_in = regB;      // dato = Rm

    ram_data u_ram (
        .clk(clk), .we(ram_we),
        .addr(ram_addr),
        .data_in(ram_data_in),
        .data_out(ram_data_out)
    );

endmodule
