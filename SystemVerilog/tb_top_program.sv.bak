`timescale 1ns/1ps

module tb_top_program;

    // Señales del top
    logic        CLOCK_50;
    logic [3:0]  KEY;
    logic        mosi, sck, ss, req;
    logic        ack;
    logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4;

    // Instancia del DUT
    top_program dut (
        .CLOCK_50 (CLOCK_50),
        .KEY      (KEY),
        .mosi     (mosi),
        .sck      (sck),
        .ss       (ss),
        .req      (req),
        .ack      (ack),
        .HEX0     (HEX0),
        .HEX1     (HEX1),
        .HEX2     (HEX2),
        .HEX3     (HEX3),
        .HEX4     (HEX4)
    );

    // =====================================================
    // 1) Reloj principal
    // =====================================================
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;  // periodo 20ns
    end

    // =====================================================
    // 2) FORZAR clk_cpu = CLOCK_50 en simulación
    //    (para no esperar el divisor gigante)
    // =====================================================
    initial begin
        // Esperamos a que el diseño esté inicializado
        #1;
        force dut.clk_cpu = CLOCK_50;
    end

    // =====================================================
    // 3) Reset y señales iniciales
    // =====================================================
    initial begin
        // Reset activo en bajo: KEY[0] = 0
        KEY        = 4'b0000;
        mosi       = 1'b0;
        sck        = 1'b0;
        ss         = 1'b1;   // SS inactivo (alto)
        req        = 1'b0;

        // Mantener reset un rato
        #100;
        KEY[0] = 1'b1;   // quitar reset
        req    = 1'b1;   // sesión "activa" para el SPI_io
    end

    // =====================================================
    // 4) Tarea: enviar un nibble por SPI (similar al Arduino)
    //     - MSB primero
    //     - ss=0 durante el envío
    //     - sck sube y baja en cada bit
    // =====================================================
    task automatic send_nibble(input [3:0] val);
        integer i;
        begin
            ss = 1'b0;   // activar esclavo
            #20;
            for (i = 3; i >= 0; i = i - 1) begin
                mosi = val[i];
                #5;
                sck = 1'b1;
                #10;
                sck = 1'b0;
                #5;
            end
            ss = 1'b1;   // desactivar esclavo → flanco de subida de SS
            #40;         // pequeño tiempo entre nibbles
        end
    endtask

    // =====================================================
    // 5) Tarea: enviar expresión A op B
    //    op_code:
    //      1 = '+'
    //      2 = '-'
    //      3 = '*'
    //      4 = '/'
    // =====================================================
    task automatic send_expr(input [3:0] A, input [3:0] op, input [3:0] B);
        begin
            $display("\n=== Enviando expresión: A=%0d, op=%0d, B=%0d @t=%0t ===",
                     A, op, B, $time);
            send_nibble(A);
            send_nibble(op);
            send_nibble(B);
        end
    endtask

    // =====================================================
    // 6) Secuencia de prueba
    // =====================================================
    initial begin
        // Esperar a que salga de reset y se estabilice
        #500;

        // Enviar 5 + 2  (op_code=1)
        send_expr(4'd5, 4'd1, 4'd2);

        // Dar tiempo para que el CPU ejecute el programa
        // (PC recorra 0..N, llegue a las instrucciones de suma/resta)
        #5000;

        // Enviar 8 - 3  (op_code=2)
        send_expr(4'd8, 4'd2, 4'd3);

        #5000;

        // Enviar 4 * 3  (op_code=3)
        send_expr(4'd4, 4'd3, 4'd3);

        #5000;

        // Enviar 8 / 2  (op_code=4)
        send_expr(4'd8, 4'd4, 4'd2);

        #10000;

        $display("\n=== FIN DE SIMULACIÓN ===");
        $finish;
    end

    // =====================================================
    // 7) Monitor de debug en cada flanco de clk_cpu
    //    Mostramos:
    //      - PC
    //      - A_VAL, B_VAL, op_code
    //      - alu_result_out
    //      - result_nib
    //      - got_cmd, in_state, load_state
    // =====================================================
    always @(posedge dut.clk_cpu) begin
        $display("t=%0t | PC=%0d | A=%0d B=%0d op=%0d | ALU=%h | RES_NIB=%0d | got_cmd=%b | in_state=%0d | load_state=%0d",
                 $time,
                 dut.pc_dbg,
                 dut.A_VAL,
                 dut.B_VAL,
                 dut.op_code,
                 dut.alu_result_out,
                 dut.result_nib,
                 dut.got_cmd,
                 dut.in_state,
                 dut.load_state);
    end

    // =====================================================
    // 8) (Opcional) monitor de los HEX para ver qué se ve
    // =====================================================
    always @(posedge dut.clk_cpu) begin
        $display("   HEX0(A)=%b HEX1(B)=%b HEX2(RES)=%b HEX3(OP)=%b HEX4(ALU)=%b",
                 HEX0, HEX1, HEX2, HEX3, HEX4);
    end

endmodule
