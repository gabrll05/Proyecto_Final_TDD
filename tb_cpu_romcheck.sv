// ============================================================
// tb_cpu_romcheck.sv
// Testbench con logs de BRANCH, STR, LDR y writeback (sin emojis)
// ============================================================
`timescale 1ns/1ps

module tb_cpu_romcheck;

    logic clk;
    logic reset;
    logic [31:0] alu_result_out;

    cpu_armv4 uut (
        .clk(clk),
        .reset(reset),
        .alu_result_out(alu_result_out)
    );

    // Reloj: periodo 10 us
    initial clk = 0;
    always #5000 clk = ~clk;

    // Secuencia principal
    initial begin
        $display("==============================================");
        $display("INICIO DE SIMULACION - PRUEBA ROM + CPU + RAM");
        $display("==============================================\n");

        reset = 1;
        #20000;
        reset = 0;

        // Ejecutar un tiempo suficiente (400 ciclos)
        #4000000;

        // Mostrar estado final de registros y memoria
        $display("\n--------------------------------");
        $display("ESTADO FINAL DE REGISTROS (r0..r7)");
        $display("--------------------------------");
        for (int r = 0; r < 8; r++) begin
            $display("r%0d = %08h", r, uut.u_regfile.registers[r]);
        end

        $display("\n--------------------------------");
        $display("ESTADO FINAL DE LA MEMORIA");
        $display("--------------------------------");
        for (int i = 0; i < 8; i++) begin
            if (uut.u_ram.mem_array[i] !== 32'hxxxxxxxx)
                $display("MEM[%0d] = %08h", i, uut.u_ram.mem_array[i]);
        end

        $display("\nFIN DE SIMULACION");
        $stop;
    end

    // Monitoreo general por instrucción (mientras PC < 20)
    always @(posedge clk) begin
        if (!reset && (^uut.instr !== 1'bx) && uut.pc < 8'd20) begin
            $display("t=%0t | PC=%0d | Instr=%08h | ALU=%0d | WR_en=%b Rd=%0d | wb_mem=%b | ram_we=%b",
                     $time, uut.pc, uut.instr, uut.alu_result_out,
                     uut.reg_wr_en, uut.reg_wr, uut.wb_sel_mem, uut.ram_we);
        end
    end

    // Evento STR: escribir RAM (usa señales ya cableadas en cpu_armv4)
    always @(posedge clk) begin
        if (!reset && uut.ram_we) begin
            $display("  STR  @t=%0t | addr=%0d (0x%02h) <= data=%08h  (Rn=regA, dato=regB=Rd)",
                     $time, uut.ram_addr, uut.ram_addr, uut.ram_data_in);
        end
    end

    // Evento LDR: writeback desde RAM
    always @(posedge clk) begin
        if (!reset && uut.wb_sel_mem && uut.reg_wr_en) begin
            // wb_data es jerárquico en cpu_armv4
            $display("  LDR  @t=%0t | Rd=r%0d <= MEM[addr=%0d] = %08h",
                     $time, uut.reg_wr, uut.ram_addr, uut.ram_data_out);
        end
    end

    // Evento BRANCH: mostrar salto relativo y next PC que aplicará el datapath
    // Requiere que la control_unit exponga branch_en/branch_imm y el PC se calcule como en cpu_armv4.
    always @(posedge clk) begin
        if (!reset && uut.u_ctrl.branch_en) begin
            logic [31:0] next_pc_full;
            next_pc_full = {24'd0, uut.pc} + 32'd1 + uut.u_ctrl.branch_imm;
            $display("  BR   @t=%0t | branch_imm=%0d -> next_pc=%0d (0x%02h)",
                     $time, $signed(uut.u_ctrl.branch_imm),
                     next_pc_full[7:0], next_pc_full[7:0]);
        end
    end

endmodule
