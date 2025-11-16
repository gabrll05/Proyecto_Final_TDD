// ============================================================
// tb_cpu_param_plusargs.sv  (ACTUALIZADO PARA cpu_armv4 con ext_*)
// Testbench: A y B parametrizables vía +A=<int> +B=<int>
// ============================================================

// synthesis translate_off
`timescale 1ns/1ps

module tb_cpu_romcheck;

    // ---------------- Señales TB ----------------
    logic        clk;
    logic        reset;
    logic [31:0] alu_result_out;

    // Valores A y B (defaults)
    integer A = 4;
    integer B = 2;

    // --------------- DUT: cpu_armv4 ---------------
    // Nota: ahora cpu_armv4 tiene puertos ext_we, ext_addr, ext_wdata
    cpu_armv4 uut (
        .clk        (clk),
        .reset      (reset),
        .ext_we     (1'b0),          // en este TB no usamos acceso externo
        .ext_addr   (8'd0),
        .ext_wdata  (32'd0),
        .alu_result_out(alu_result_out)
    );

    // --------------- Reloj: periodo 10 us ---------------
    initial clk = 0;
    always #5000 clk = ~clk;

    // --------------- Secuencia principal ---------------
    initial begin
        $display("==============================================");
        $display("INICIO DE SIMULACION - PRUEBA ROM + CPU + RAM");
        $display("==============================================\n");

        // Lee plusargs si vienen: +A=<int> +B=<int>
        if ($value$plusargs("A=%d", A)) $display("[TB] A pasado por plusargs: %0d", A);
        if ($value$plusargs("B=%d", B)) $display("[TB] B pasado por plusargs: %0d", B);

        $display("[TB] Parametros efectivos: A=%0d, B=%0d (MEM[10]=A, MEM[11]=B, resultado en MEM[12] y r3)", A, B);

        // Reset y precarga de RAM ANTES de soltar reset
        reset = 1;

        // RAM interna del CPU: uut.u_ram.mem_array
        uut.u_ram.mem_array[10] = A;        // A
        uut.u_ram.mem_array[11] = B;        // B
        uut.u_ram.mem_array[12] = 32'h0;    // limpia celda de salida

        // Mantener reset por 20 us
        #20000;
        reset = 0;

        // Ejecutar ~400 ciclos (4 ms a 10us/ciclo)
        #4000000;

        // --------- Estado final ----------
        $display("\n--------------------------------");
        $display("ESTADO FINAL DE REGISTROS (r0..r7)");
        $display("--------------------------------");
        for (int r = 0; r < 8; r++) begin
            $display("r%0d = %08h", r, uut.u_regfile.registers[r]);
        end

        $display("\n--------------------------------");
        $display("ESTADO FINAL DE LA MEMORIA (0..15)");
        $display("--------------------------------");
        for (int i = 0; i < 16; i++) begin
            if (uut.u_ram.mem_array[i] !== 32'hxxxxxxxx)
                $display("MEM[%0d] = %08h", i, uut.u_ram.mem_array[i]);
        end

        $display("\nFIN DE SIMULACION");
        $stop;
    end

    // --------- Monitoreo por instrucción (mientras PC < 20) ---------
    always @(posedge clk) begin
        if (!reset && (^uut.instr !== 1'bx) && uut.pc < 8'd20) begin
            $display("t=%0t | PC=%0d | Instr=%08h | ALU=%0d | WR_en=%b Rd=%0d | wb_mem=%b | ram_we=%b",
                     $time, uut.pc, uut.instr, uut.alu_result_out,
                     uut.reg_wr_en, uut.reg_wr, uut.wb_sel_mem, uut.ram_we_internal);
        end
    end

    // --------- Evento STR: escritura a RAM ---------
    always @(posedge clk) begin
        if (!reset && uut.ram_we_internal) begin
            $display("  STR  @t=%0t | addr=%0d (0x%02h) <= data=%08h",
                     $time,
                     uut.ram_addr_internal, uut.ram_addr_internal,
                     uut.ram_data_in_internal);
        end
    end

    // --------- Evento LDR: writeback desde RAM ---------
    always @(posedge clk) begin
        if (!reset && uut.wb_sel_mem && uut.reg_wr_en) begin
            $display("  LDR  @t=%0t | Rd=r%0d <= MEM[addr=%0d] = %08h",
                     $time, uut.reg_wr, uut.ram_addr_internal, uut.ram_data_out);
        end
    end

    // --------- Evento BRANCH: salto relativo ---------
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
// synthesis translate_on
