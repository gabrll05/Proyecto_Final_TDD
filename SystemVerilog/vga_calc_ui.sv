// ============================================================
// vga_calc_ui.sv  (VERSIÓN VERTICAL, DÍGITOS PEQUEÑOS, A/B FIX)
// Layout:
//
// A : valor
// B : valor
// + : valor
// - : valor
// * : valor
// / : valor
// ============================================================

module vga_calc_ui (
    input  logic [11:0] x,
    input  logic [11:0] y,
    input  logic        video_on,

    input  logic [3:0]  A_nib,
    input  logic [3:0]  B_nib,
    input  logic [3:0]  sum_nib,
    input  logic [3:0]  sub_nib,
    input  logic [3:0]  mul_nib,
    input  logic [3:0]  div_nib,

    output logic [7:0]  vga_r,
    output logic [7:0]  vga_g,
    output logic [7:0]  vga_b
);

    // --------------------------
    // Constantes de layout
    // --------------------------
    // Columna de labels
    localparam integer LABEL_X   = 60;
    // Columna de valores
    localparam integer VALUE_X   = 170;

    // Primera fila y separación vertical entre filas
    localparam integer ROW0_Y    = 80;
    localparam integer ROW_SP    = 60;

    // Tamaño de los dígitos grandes
    localparam integer DIGIT_W   = 26;
    localparam integer DIGIT_H   = 48;
    localparam integer SEG_TH    = 4;   // grosor de trazo

    // --------------------------
    // Variables internas
    // --------------------------
    logic [6:0] seg_A_lbl;
    logic [6:0] seg_B_lbl;

    logic [6:0] segA;
    logic [6:0] segB;
    logic [6:0] segSUM;
    logic [6:0] segSUB;
    logic [6:0] segMUL;
    logic [6:0] segDIV;

    integer  dx_mul, dy_mul;
    integer  dx_div, dy_div;
    logic    is_plus_seg_mul;
    logic    is_diag_seg_mul;

    integer cx_plus,  cy_plus;
    integer cx_minus, cy_minus;
    integer cx_mul,   cy_mul;
    integer cx_div,   cy_div;

    integer colon_x;
    integer r;
    integer baseY;

    // --------------------------
    // Helpers
    // --------------------------
    function automatic logic in_rect(
        input logic [11:0] px,
        input logic [11:0] py,
        input integer      x0,
        input integer      x1,
        input integer      y0,
        input integer      y1
    );
        in_rect = (px >= x0 && px < x1 && py >= y0 && py < y1);
    endfunction

    // Mapa 7 segmentos: [6]=a,[5]=b,[4]=c,[3]=d,[2]=e,[1]=f,[0]=g
    function automatic logic [6:0] hex_to_segs(input logic [3:0] v);
        case (v)
            4'h0: hex_to_segs = 7'b1111110;
            4'h1: hex_to_segs = 7'b0110000;
            4'h2: hex_to_segs = 7'b1101101;
            4'h3: hex_to_segs = 7'b1111001;
            // 4 más "marcado": b, c, f, g encendidos
            4'h4: hex_to_segs = 7'b0110011;
            4'h5: hex_to_segs = 7'b1011011;
            4'h6: hex_to_segs = 7'b1011111;
            4'h7: hex_to_segs = 7'b1110000;
            4'h8: hex_to_segs = 7'b1111111;
            4'h9: hex_to_segs = 7'b1111011;
            4'hA: hex_to_segs = 7'b1110111; // A
            4'hB: hex_to_segs = 7'b0011111; // b
            4'hC: hex_to_segs = 7'b1001110; // C
            4'hD: hex_to_segs = 7'b0111101; // d
            4'hE: hex_to_segs = 7'b1001111; // E
            4'hF: hex_to_segs = 7'b1000111; // F
            default: hex_to_segs = 7'b0000001;
        endcase
    endfunction

    // Dibuja un dígito 7-seg de tamaño reducido
    function automatic logic digit_pixel(
        input logic [11:0] px,
        input logic [11:0] py,
        input integer      dx,
        input integer      dy,
        input logic [6:0]  segs
    );
        integer W;
        integer H;
        integer TH;

        logic hit;
        integer my0, my1;

        begin
            W  = DIGIT_W;
            H  = DIGIT_H;
            TH = SEG_TH;
            hit = 1'b0;

            // Horizontales
            if (segs[6]) begin // a
                if (in_rect(px, py, dx+5, dx+W-5, dy, dy+TH))
                    hit = 1'b1;
            end
            if (segs[3]) begin // d (medio)
                my0 = dy + (H/2) - (TH/2);
                my1 = my0 + TH;
                if (in_rect(px, py, dx+5, dx+W-5, my0, my1))
                    hit = 1'b1;
            end
            if (segs[0]) begin // g (abajo)
                if (in_rect(px, py, dx+5, dx+W-5, dy+H-TH, dy+H))
                    hit = 1'b1;
            end

            // Verticales
            if (segs[5]) begin // b
                if (in_rect(px, py, dx+W-TH, dx+W, dy+TH, dy+H/2))
                    hit = 1'b1;
            end
            if (segs[4]) begin // c
                if (in_rect(px, py, dx+W-TH, dx+W, dy+H/2, dy+H-TH))
                    hit = 1'b1;
            end
            if (segs[1]) begin // f
                if (in_rect(px, py, dx, dx+TH, dy+TH, dy+H/2))
                    hit = 1'b1;
            end
            if (segs[2]) begin // e
                if (in_rect(px, py, dx, dx+TH, dy+H/2, dy+H-TH))
                    hit = 1'b1;
            end

            digit_pixel = hit;
        end
    endfunction

    // --------------------------
    // Lógica principal
    // --------------------------
    always_comb begin
        // defaults
        vga_r = 8'h00;
        vga_g = 8'h00;
        vga_b = 8'h00;

        seg_A_lbl = 7'd0;
        seg_B_lbl = 7'd0;

        segA   = 7'd0;
        segB   = 7'd0;
        segSUM = 7'd0;
        segSUB = 7'd0;
        segMUL = 7'd0;
        segDIV = 7'd0;

        dx_mul = 0; dy_mul = 0;
        dx_div = 0; dy_div = 0;

        is_plus_seg_mul = 1'b0;
        is_diag_seg_mul = 1'b0;

        cx_plus  = 0; cy_plus  = 0;
        cx_minus = 0; cy_minus = 0;
        cx_mul   = 0; cy_mul   = 0;
        cx_div   = 0; cy_div   = 0;

        colon_x = 0;
        r       = 0;
        baseY   = 0;

        if (!video_on) begin
            // negro
        end else begin
            // fondo blanco
            vga_r = 8'hFF;
            vga_g = 8'hFF;
            vga_b = 8'hFF;

            // franja superior
            if (in_rect(x, y, 0, 640, 20, 70)) begin
                vga_r = 8'hE0;
                vga_g = 8'hE0;
                vga_b = 8'hE0;
            end

            // ===== Labels A y B (patrones fijos) =====
            // A: segmentos a,b,c,e,f,g encendidos, d apagado
            seg_A_lbl = 7'b1110111;
            // B: estilo "B" en 7-seg (parte baja algo abierta)
            seg_B_lbl = 7'b0011111;

            if (digit_pixel(x, y, LABEL_X, ROW0_Y, seg_A_lbl))
                {vga_r, vga_g, vga_b} = 24'h000000;

            if (digit_pixel(x, y, LABEL_X, ROW0_Y + ROW_SP, seg_B_lbl))
                {vga_r, vga_g, vga_b} = 24'h000000;

            // ===== Operadores =====
            cx_plus  = LABEL_X + DIGIT_W/2;
            cy_plus  = ROW0_Y + 2*ROW_SP + DIGIT_H/2;
            cx_minus = LABEL_X + DIGIT_W/2;
            cy_minus = ROW0_Y + 3*ROW_SP + DIGIT_H/2;
            cx_mul   = LABEL_X + DIGIT_W/2;
            cy_mul   = ROW0_Y + 4*ROW_SP + DIGIT_H/2;
            cx_div   = LABEL_X + DIGIT_W/2;
            cy_div   = ROW0_Y + 5*ROW_SP + DIGIT_H/2;

            // +
            if ( in_rect(x, y, cx_plus-2,  cx_plus+2,  cy_plus-10, cy_plus+10) ||
                 in_rect(x, y, cx_plus-10, cx_plus+10, cy_plus-2,  cy_plus+2) )
                {vga_r, vga_g, vga_b} = 24'h000000;

            // -
            if ( in_rect(x, y, cx_minus-10, cx_minus+10, cy_minus-2, cy_minus+2) )
                {vga_r, vga_g, vga_b} = 24'h000000;

            // *
            dx_mul = $signed(x) - $signed(cx_mul);
            dy_mul = $signed(y) - $signed(cy_mul);
            is_plus_seg_mul =
                in_rect(x, y, cx_mul-2,  cx_mul+2,  cy_mul-10, cy_mul+10) ||
                in_rect(x, y, cx_mul-10, cx_mul+10, cy_mul-2,  cy_mul+2);
            is_diag_seg_mul =
                ((dy_mul + dx_mul) > -2 && (dy_mul + dx_mul) < 2 && dy_mul > -10 && dy_mul < 10) ||
                ((dy_mul - dx_mul) > -2 && (dy_mul - dx_mul) < 2 && dy_mul > -10 && dy_mul < 10);
            if (is_plus_seg_mul || is_diag_seg_mul)
                {vga_r, vga_g, vga_b} = 24'h000000;

            // /
            dx_div = $signed(x) - $signed(cx_div);
            dy_div = $signed(y) - $signed(cy_div);
            if ((dy_div + dx_div) > -2 && (dy_div + dx_div) < 2 && dy_div > -12 && dy_div < 12)
                {vga_r, vga_g, vga_b} = 24'h000000;

            // ===== Valores grandes =====
            segA   = hex_to_segs(A_nib);
            segB   = hex_to_segs(B_nib);
            segSUM = hex_to_segs(sum_nib);
            segSUB = hex_to_segs(sub_nib);
            segMUL = hex_to_segs(mul_nib);
            segDIV = hex_to_segs(div_nib);

            if (digit_pixel(x, y, VALUE_X, ROW0_Y,               segA)   ||
                digit_pixel(x, y, VALUE_X, ROW0_Y + ROW_SP,      segB)   ||
                digit_pixel(x, y, VALUE_X, ROW0_Y + 2*ROW_SP,    segSUM) ||
                digit_pixel(x, y, VALUE_X, ROW0_Y + 3*ROW_SP,    segSUB) ||
                digit_pixel(x, y, VALUE_X, ROW0_Y + 4*ROW_SP,    segMUL) ||
                digit_pixel(x, y, VALUE_X, ROW0_Y + 5*ROW_SP,    segDIV))
                {vga_r, vga_g, vga_b} = 24'h000000;

            // ===== Puntos ":" entre label y valor =====
            colon_x = (LABEL_X + VALUE_X) / 2;
            for (r = 0; r < 6; r = r + 1) begin
                baseY = ROW0_Y + r*ROW_SP + 16;
                if ( in_rect(x, y, colon_x-2, colon_x+2, baseY,    baseY+3) ||
                     in_rect(x, y, colon_x-2, colon_x+2, baseY+16, baseY+19))
                    {vga_r, vga_g, vga_b} = 24'h000000;
            end
        end
    end

endmodule
