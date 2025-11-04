// ============================================================
// tb_cpu_romcheck.sv
// Testbench limpio con filtros y fin automático
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

    // Reloj
    initial clk = 0;
    always #5000 clk = ~clk;   // 10us periodo

    // Secuencia principal
    initial begin
        $display("==============================================");
        $display("🚀 INICIO DE SIMULACIÓN - PRUEBA ROM + CPU + RAM");
        $display("==============================================\n");

        reset = 1;
        #20000;
        reset = 0;

        // Ejecutar por tiempo suficiente
        #4000000;

        // Mostrar estado final
        $display("\n--------------------------------");
        $display("📦 ESTADO FINAL DE LA MEMORIA");
        $display("--------------------------------");
        for (int i = 0; i < 8; i++) begin
            if (uut.u_ram.mem_array[i] !== 32'hxxxxxxxx)
                $display("MEM[%0d] = %h", i, uut.u_ram.mem_array[i]);
        end

        $display("\n✅ FIN DE SIMULACIÓN");
        $stop;
    end

    // Monitoreo filtrado
    always @(posedge clk) begin
        if (^uut.instr !== 1'bx && uut.pc < 8'd20) begin
            $display("t=%0t | PC=%0d | Instr=%h | ALU=%0d | WR_en=%b | RegW=%0d",
                     $time, uut.pc, uut.instr, uut.alu_result_out,
                     uut.reg_wr_en, uut.reg_wr);
        end
    end

endmodule
