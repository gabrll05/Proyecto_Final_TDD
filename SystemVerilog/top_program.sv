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
    output logic [6:0]  HEX4
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
    // SPI: recibe un número de 4 bits
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

    assign ack = spi_ack_raw;

    // ----------------------------------------------------
    // Dominio rápido (CLOCK_50): latch del dato + toggle
    // ----------------------------------------------------
    logic [3:0] spi_data_fast;
    logic       spi_toggle_fast;

    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            spi_data_fast   <= 4'd0;
            spi_toggle_fast <= 1'b0;
        end else begin
            if (spi_ack_raw) begin
                spi_data_fast   <= spi_data_raw;
                spi_toggle_fast <= ~spi_toggle_fast;
            end
        end
    end

    // ----------------------------------------------------
    // Sincronizar al dominio del CPU (clk_cpu)
    // ----------------------------------------------------
    logic       spi_toggle_sync0, spi_toggle_sync1;
    logic [3:0] spi_data_sync0, spi_data_sync1;

    always_ff @(posedge clk_cpu or posedge reset) begin
        if (reset) begin
            spi_toggle_sync0 <= 1'b0;
            spi_toggle_sync1 <= 1'b0;
            spi_data_sync0   <= 4'd0;
            spi_data_sync1   <= 4'd0;
        end else begin
            spi_toggle_sync0 <= spi_toggle_fast;
            spi_toggle_sync1 <= spi_toggle_sync0;

            spi_data_sync0   <= spi_data_fast;
            spi_data_sync1   <= spi_data_sync0;
        end
    end

    // Pulso cuando llega un nuevo dato SPI visto por el CPU
    wire new_spi_cpu = spi_toggle_sync0 ^ spi_toggle_sync1;

    // ----------------------------------------------------
    // Lógica para latch de A y saber que ya tenemos SPI
    // ----------------------------------------------------
    logic        got_spi;     // ya recibimos al menos un valor por SPI
    logic [3:0]  A_VAL;       // valor A visible en HEX
    localparam logic [3:0] B_VAL = 4'd2;  // B fijo = 2

    always_ff @(posedge clk_cpu or posedge reset) begin
        if (reset) begin
            got_spi <= 1'b0;
            A_VAL   <= 4'd0;
        end else begin
            if (new_spi_cpu) begin
                got_spi <= 1'b1;
                A_VAL   <= spi_data_sync1;   // A = lo que llegó por SPI
            end
        end
    end

    // ----------------------------------------------------
    // Pequeño FSM para escribir A y B en la RAM interna
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
                    if (new_spi_cpu)
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
                ext_wdata_sig = {28'd0, spi_data_sync1};
            end
            LOAD_B: begin
                // Escribimos B = 2 en MEM[11]
                ext_we_sig    = 1'b1;
                ext_addr_sig  = 8'd11;
                ext_wdata_sig = 32'd2;
            end
            default: ; // nada
        endcase
    end

    // CPU en reset mientras:
    //  - haya reset global
    //  - aún no haya llegado ningún valor SPI (got_spi=0)
    //  - estemos en la secuencia de carga (LOAD_A o LOAD_B)
    logic cpu_reset;
    assign cpu_reset = reset | (~got_spi) | (load_state != LOAD_IDLE);

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
    // Captura de resultados de operaciones
    //  PC = 5 -> ADD r2 = A + B
    //  PC = 6 -> SUB r3 = A - B
    // ----------------------------------------------------
    logic [3:0] sum_res_nib;
    logic [3:0] sub_res_nib;

    always_ff @(posedge clk_cpu or posedge cpu_reset) begin
        if (cpu_reset) begin
            sum_res_nib <= 4'd0;
            sub_res_nib <= 4'd0;
        end else begin
            case (pc_dbg)
                8'd5: sum_res_nib <= alu_result_out[3:0]; // ADD A+B
                8'd6: sub_res_nib <= alu_result_out[3:0]; // SUB A-B
                default: ; // mantiene valor anterior
            endcase
        end
    end

    // ----------------------------------------------------
    // Displays 7 segmentos
    // ----------------------------------------------------

    // HEX0: valor A (desde SPI)
    seven_segment_display u_hex_A (
        .sev_seg_in (A_VAL),
        .sev_seg_out(HEX0)
    );

    // HEX1: B fijo = 2
    seven_segment_display u_hex_B (
        .sev_seg_in (B_VAL),
        .sev_seg_out(HEX1)
    );

    // HEX2: resultado de la suma A+B
    seven_segment_display u_hex_SUM (
        .sev_seg_in (sum_res_nib),
        .sev_seg_out(HEX2)
    );

    // HEX3: resultado de la resta A-B
    seven_segment_display u_hex_SUB (
        .sev_seg_in (sub_res_nib),
        .sev_seg_out(HEX3)
    );

    // HEX4: nibble actual de la ALU (carrusel del programa)
    seven_segment_display u_hex_ALU (
        .sev_seg_in (alu_result_out[3:0]),
        .sev_seg_out(HEX4)
    );

endmodule
