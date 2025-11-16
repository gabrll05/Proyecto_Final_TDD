// ============================================================
// top_program.sv
// Top del proyecto: SPI -> RAM CPU -> ALU -> VGA Calculadora
//  - Ahora el SPI SOLO recibe A y B como nibbles (no signo).
//  - El CPU siempre calcula suma, resta, mul y div con A y B.
//  - VGA muestra A, B y los resultados.
// ============================================================

module top_program (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,      // KEY[0] = reset activo en bajo

    // === Pines SPI ===
    input  logic        mosi,
    input  logic        sck,
    input  logic        ss,
    input  logic        req,
    output logic        ack,

    // === Displays 7 segmentos (DE10 tiene 5) ===
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,

    // === Salidas VGA ===
    output logic        VGA_HS,
    output logic        VGA_VS,
    output logic [7:0]  VGA_R,
    output logic [7:0]  VGA_G,
    output logic [7:0]  VGA_B,
    output logic        VGA_CLK,
    output logic        VGA_BLANK_N,
    output logic        VGA_SYNC_N
);

    // ----------------------------------------------------
    // Reset global y reloj lento del CPU
    // ----------------------------------------------------
    logic clk_cpu;
    logic rst_n;   // del botón, activo en bajo
    logic reset;   // interno, activo en alto

    assign rst_n = KEY[0];   // KEY[0]=0 → reset apretado
    assign reset = ~rst_n;   // reset interno alto cuando KEY[0]=0

    // Divisor de reloj (CPU más lento para poder ver en hex)
    clock_divider u_div (
        .clk_in (CLOCK_50),
        .rst_n  (rst_n),     // reset activo en bajo
        .clk_out(clk_cpu)
    );

    // ----------------------------------------------------
    // SPI: recibe un nibble (4 bits) + ACK de handshake
    // ----------------------------------------------------
    logic [3:0] spi_data_raw;
    logic       spi_ack_raw;

    SPI_io u_spi (
        .rst                  (rst_n),          // rst_n activo en bajo
        .mosi                 (mosi),
        .sck                  (sck),
        .req                  (req),
        .ss                   (ss),
        .ack                  (spi_ack_raw),
        .master_data_register (spi_data_raw)
    );

    // ACK sólo lo reenviamos al Arduino (para el handshake)
    assign ack = spi_ack_raw;

    // ----------------------------------------------------
    // Dominio rápido (CLOCK_50): detectar fin de nibble
    // usando flanco de subida de SS
    // ----------------------------------------------------
    logic       ss_sync0, ss_sync1, ss_prev;
    logic       ss_rise;
    logic [3:0] spi_data_fast;

    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            ss_sync0      <= 1'b1;
            ss_sync1      <= 1'b1;
            ss_prev       <= 1'b1;
            ss_rise       <= 1'b0;
            spi_data_fast <= 4'd0;
        end else begin
            // Sincronizar SS al reloj de 50 MHz
            ss_sync0 <= ss;
            ss_sync1 <= ss_sync0;

            // Detectar flanco de subida de SS (0 -> 1)
            ss_rise <= ss_sync1 & ~ss_prev;
            ss_prev <= ss_sync1;

            if (ss_rise) begin
                // Cuando SS sube, el nibble ya fue shift-eado en md
                spi_data_fast <= spi_data_raw;
            end
        end
    end

    // ----------------------------------------------------
    // Sincronizar nibble al dominio del CPU (clk_cpu)
    // y detectar CAMBIO de nibble (nuevo dato)
    // ----------------------------------------------------
    logic [3:0] nibble_sync0, nibble_sync1, nibble_last;
    logic       new_word_cpu;

    always_ff @(posedge clk_cpu or posedge reset) begin
        if (reset) begin
            nibble_sync0 <= 4'd0;
            nibble_sync1 <= 4'd0;
            nibble_last  <= 4'd0;
            new_word_cpu <= 1'b0;
        end else begin
            // doble sincronización del dato desde el dominio de CLOCK_50
            nibble_sync0 <= spi_data_fast;
            nibble_sync1 <= nibble_sync0;

            // si cambió el nibble estable → nuevo "word" recibido
            if (nibble_sync1 != nibble_last) begin
                nibble_last  <= nibble_sync1;
                new_word_cpu <= 1'b1;   // pulso de 1 ciclo
            end else begin
                new_word_cpu <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------
    // FSM de entrada: recibir SOLO A y luego B
    //    - Primer nibble  -> A_VAL
    //    - Segundo nibble -> B_VAL, se marca got_cmd
    // ----------------------------------------------------
    typedef enum logic [1:0] {
        IN_WAIT_A  = 2'd0,
        IN_WAIT_B  = 2'd1
    } input_state_t;

    input_state_t in_state;
    logic         got_cmd;      // al menos un comando completo recibido
    logic [3:0]   A_VAL;        // operando A
    logic [3:0]   B_VAL;        // operando B
    logic [3:0]   op_code;      // ya no viene de SPI, lo dejamos en 0

    always_ff @(posedge clk_cpu or posedge reset) begin
        if (reset) begin
            in_state <= IN_WAIT_A;
            A_VAL    <= 4'd0;
            B_VAL    <= 4'd0;
            op_code  <= 4'd0;   // en reset y siempre 0
            got_cmd  <= 1'b0;
        end else begin
            if (new_word_cpu) begin
                case (in_state)
                    IN_WAIT_A: begin
                        // Primer nibble recibido -> A
                        A_VAL    <= nibble_last;
                        in_state <= IN_WAIT_B;
                    end

                    IN_WAIT_B: begin
                        // Segundo nibble -> B, ya tenemos comando completo
                        B_VAL    <= nibble_last;
                        in_state <= IN_WAIT_A;
                        got_cmd  <= 1'b1;
                    end

                    default: in_state <= IN_WAIT_A;
                endcase
            end
        end
    end

    // Pulso para iniciar carga en RAM cuando terminamos de recibir B
    logic cmd_start_reg;
    wire  cmd_start = cmd_start_reg;

    always_ff @(posedge clk_cpu or posedge reset) begin
        if (reset) begin
            cmd_start_reg <= 1'b0;
        end else begin
            if (new_word_cpu && (in_state == IN_WAIT_B))
                cmd_start_reg <= 1'b1;
            else
                cmd_start_reg <= 1'b0;
        end
    end

    // ----------------------------------------------------
    // FSM para escribir A y B en la RAM interna del CPU
    // ----------------------------------------------------
    typedef enum logic [1:0] {
        LOAD_IDLE = 2'd0,
        LOAD_A    = 2'd1,
        LOAD_B    = 2'd2
    } load_state_t;

    load_state_t load_state;

    always_ff @(posedge clk_cpu or posedge reset) begin
        if (reset) begin
            load_state <= LOAD_IDLE;
        end else begin
            case (load_state)
                LOAD_IDLE: begin
                    if (cmd_start)
                        load_state <= LOAD_A;   // empieza secuencia de carga
                end
                LOAD_A: begin
                    load_state <= LOAD_B;       // siguiente ciclo: cargar B
                end
                LOAD_B: begin
                    load_state <= LOAD_IDLE;    // termina carga, luego CPU corre
                end
                default: load_state <= LOAD_IDLE;
            endcase
        end
    end

    // Señales de escritura externa a la RAM del CPU
    logic        ext_we_sig;
    logic [7:0]  ext_addr_sig;
    logic [31:0] ext_wdata_sig;

    always_comb begin
        // valores por defecto (no escribir)
        ext_we_sig    = 1'b0;
        ext_addr_sig  = 8'd0;
        ext_wdata_sig = 32'd0;

        case (load_state)
            LOAD_A: begin
                // Escribimos A en MEM[10]
                ext_we_sig    = 1'b1;
                ext_addr_sig  = 8'd10;
                ext_wdata_sig = {28'd0, A_VAL};
            end
            LOAD_B: begin
                // Escribimos B en MEM[11]
                ext_we_sig    = 1'b1;
                ext_addr_sig  = 8'd11;
                ext_wdata_sig = {28'd0, B_VAL};
            end
            default: ; // nada
        endcase
    end

    // CPU en reset mientras:
    //  - haya reset global
    //  - aún no haya llegado ningún comando completo (got_cmd=0)
    //  - estemos en la secuencia de carga (LOAD_A o LOAD_B)
    logic cpu_reset;
    assign cpu_reset = reset | (~got_cmd) | (load_state != LOAD_IDLE);

    // ----------------------------------------------------
    // CPU ARM + interfaz externa a RAM
    // ----------------------------------------------------
    logic [31:0] alu_result_out;
    logic [7:0]  pc_dbg;

    cpu_armv4 u_cpu (
        .clk           (clk_cpu),
        .reset         (cpu_reset),

        .ext_we        (ext_we_sig),
        .ext_addr      (ext_addr_sig),
        .ext_wdata     (ext_wdata_sig),

        .alu_result_out(alu_result_out),
        .pc_out        (pc_dbg)
    );

    // ----------------------------------------------------
    // Captura de RESULTADOS (ADD, SUB, MUL, DIV)
    //  PC = 5 -> ADD r2 = A + B
    //  PC = 6 -> SUB r3 = A - B
    //  PC = 7 -> MUL r4 = A * B
    //  PC = 8 -> DIV r5 = A / B
    // ----------------------------------------------------
    logic [3:0] sum_nib, sub_nib, mul_nib, div_nib;

    always_ff @(posedge clk_cpu or posedge cpu_reset) begin
        if (cpu_reset) begin
            sum_nib <= 4'd0;
            sub_nib <= 4'd0;
            mul_nib <= 4'd0;
            div_nib <= 4'd0;
        end else begin
            case (pc_dbg)
                8'd5: sum_nib <= alu_result_out[3:0]; // suma
                8'd6: sub_nib <= alu_result_out[3:0]; // resta
                8'd7: mul_nib <= alu_result_out[3:0]; // mul
                8'd8: div_nib <= alu_result_out[3:0]; // div
                default: ; // mantiene valores
            endcase
        end
    end

    // ----------------------------------------------------
    // Displays 7 segmentos
    //  HEX0 -> A
    //  HEX1 -> B
    //  HEX2 -> resultado de la suma
    //  HEX3 -> código de operación (ahora siempre 0)
    //  HEX4 -> nibble actual de la ALU (carrusel del programa)
    // ----------------------------------------------------

    // HEX0: valor A
    seven_segment_display u_hex_A (
        .sev_seg_in (A_VAL),
        .sev_seg_out(HEX0)
    );

    // HEX1: valor B
    seven_segment_display u_hex_B (
        .sev_seg_in (B_VAL),
        .sev_seg_out(HEX1)
    );

    // HEX2: suma
    seven_segment_display u_hex_RES (
        .sev_seg_in (sum_nib),
        .sev_seg_out(HEX2)
    );

    // HEX3: código de la operación (ya no se usa, queda en 0)
    seven_segment_display u_hex_OP (
        .sev_seg_in (op_code),
        .sev_seg_out(HEX3)
    );

    // HEX4: nibble actual de la ALU (carrusel del programa)
    seven_segment_display u_hex_ALU (
        .sev_seg_in (alu_result_out[3:0]),
        .sev_seg_out(HEX4)
    );

    // ----------------------------------------------------
    // VGA: clock de píxel + reset de dominio VGA
    // ----------------------------------------------------
    logic clk_pix;
    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) clk_pix <= 1'b0;
        else       clk_pix <= ~clk_pix;   // ~25 MHz
    end

    assign VGA_CLK     = clk_pix;
    assign VGA_BLANK_N = 1'b1; // siempre activo
    assign VGA_SYNC_N  = 1'b0; // no se usa en monitores modernos

    // Reset sincronizado al dominio de píxel
    logic r1, r2;
    always_ff @(posedge clk_pix or negedge rst_n) begin
        if (!rst_n) begin
            r1 <= 1'b1;
            r2 <= 1'b1;
        end else begin
            r1 <= 1'b0;
            r2 <= r1;
        end
    end
    wire rst_pix = r2;

    // ----------------------------------------------------
    // Instancia de vga_controller (timing) + UI
    // ----------------------------------------------------
    logic       video_on;
    logic [11:0] vx, vy;
    logic        hs_int, vs_int;

    vga_controller #(
        .H_ACTIVE(640), .V_ACTIVE(480),
        .H_FP(16), .H_SYNC(96), .H_BP(48),
        .V_FP(10), .V_SYNC(2),  .V_BP(33),
        .HS_POL(1'b0), .VS_POL(1'b0)
    ) u_vga (
        .clk_pix (clk_pix),
        .rst     (rst_pix),
        .hsync   (hs_int),
        .vsync   (vs_int),
        .video_on(video_on),
        .x       (vx),
        .y       (vy)
    );

    // Registrar HS/VS para salida
    always_ff @(posedge clk_pix or negedge rst_n) begin
        if (!rst_n) begin
            VGA_HS <= 1'b1;
            VGA_VS <= 1'b1;
        end else begin
            VGA_HS <= hs_int;
            VGA_VS <= vs_int;
        end
    end

    // UI de calculadora
    logic [7:0] ui_r, ui_g, ui_b;

    vga_calc_ui u_vga_calc_ui (
        .x       (vx),
        .y       (vy),
        .video_on(video_on),

        .A_nib   (A_VAL),
        .B_nib   (B_VAL),
        .sum_nib (sum_nib),
        .sub_nib (sub_nib),
        .mul_nib (mul_nib),
        .div_nib (div_nib),

        .vga_r   (ui_r),
        .vga_g   (ui_g),
        .vga_b   (ui_b)
    );

    // Registro de color de salida
    always_ff @(posedge clk_pix or negedge rst_n) begin
        if (!rst_n) begin
            VGA_R <= 8'h00;
            VGA_G <= 8'h00;
            VGA_B <= 8'h00;
        end else if (video_on) begin
            VGA_R <= ui_r;
            VGA_G <= ui_g;
            VGA_B <= ui_b;
        end else begin
            VGA_R <= 8'h00;
            VGA_G <= 8'h00;
            VGA_B <= 8'h00;
        end
    end

endmodule
