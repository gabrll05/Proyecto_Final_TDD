// ============================================================
// vga_calc_ui.sv
// UI simple de calculadora en VGA:
//  - Fondo blanco
//  - Franja gris arriba (titulo "Calculadora" a nivel visual)
//  - Fila de labels: A, B, +, -, *, /
//  - Debajo: valor de A, B, suma, resta, mul, div (nibbles hex) en dígitos grandes
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
    localparam integer COL0_X   = 40;
    localparam integer COL1_X   = 140;
    localparam integer COL2_X   = 240;
    localparam integer COL3_X   = 340;
    localparam integer COL4_X   = 440;
    localparam integer COL5_X   = 540;

    localparam integer LABEL_Y  = 120; // fila de símbolos
    localparam integer DIGIT_Y  = 200; // fila de dígitos grandes

    localparam integer CX_PLUS  = COL2_X + 20;
    localparam integer CX_MINUS = COL3_X + 20;
    localparam integer CX_MUL   = COL4_X + 20;
    localparam integer CX_DIV   = COL5_X + 20;
    localparam integer CY_OPS   = LABEL_Y + 25;

    // --------------------------
    // Variables internas
    // --------------------------
    logic [6:0] seg_A_lbl;
    logic [6:0] seg_B_lbl;

    integer dx_mul;
    integer dy_mul;
    logic   is_plus_seg_mul;
    logic   is_diag_seg_mul;

    integer dx_div;
    integer dy_div;

    logic [6:0] segA;
    logic [6:0] segB;
    logic [6:0] segSUM;
    logic [6:0] segSUB;
    logic [6:0] segMUL;
    logic [6:0] segDIV;

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

    // Mapa de 7 segmentos: [6]=a,[5]=b,[4]=c,[3]=d,[2]=e,[1]=f,[0]=g
    function automatic logic [6:0] hex_to_segs(input logic [3:0] v);
        case (v)
            4'h0: hex_to_segs = 7'b1111110;
            4'h1: hex_to_segs = 7'b0110000;
            4'h2: hex_to_segs = 7'b1101101;
            4'h3: hex_to_segs = 7'b1111001;
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
            default: hex_to_segs = 7'b0000001; // guión
        endcase
    endfunction

    // ¿Pixel dentro del dígito 7-seg en (dx,dy)?
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
            W  = 40;
            H  = 70;
            TH = 6;
            hit = 1'b0;

            // Segmentos horizontales
            if (segs[6]) begin // a - arriba
                if (in_rect(px, py, dx+8, dx+W-8, dy, dy+TH))
                    hit = 1'b1;
            end
            if (segs[3]) begin // d - medio
                my0 = dy + (H/2) - (TH/2);
                my1 = my0 + TH;
                if (in_rect(px, py, dx+8, dx+W-8, my0, my1))
                    hit = 1'b1;
            end
            if (segs[0]) begin // g - abajo
                if (in_rect(px, py, dx+8, dx+W-8, dy+H-TH, dy+H))
                    hit = 1'b1;
            end

            // Segmentos verticales
            if (segs[5]) begin // b - arriba derecha
                if (in_rect(px, py, dx+W-TH, dx+W, dy+TH, dy+H/2))
                    hit = 1'b1;
            end
            if (segs[4]) begin // c - abajo derecha
                if (in_rect(px, py, dx+W-TH, dx+W, dy+H/2, dy+H-TH))
                    hit = 1'b1;
            end
            if (segs[1]) begin // f - arriba izquierda
                if (in_rect(px, py, dx, dx+TH, dy+TH, dy+H/2))
                    hit = 1'b1;
            end
            if (segs[2]) begin // e - abajo izquierda
                if (in_rect(px, py, dx, dx+TH, dy+H/2, dy+H-TH))
                    hit = 1'b1;
            end

            digit_pixel = hit;
        end
    endfunction

    // --------------------------
    // Lógica principal de color
    // --------------------------
    always_comb begin
        // --------- VALORES POR DEFECTO (evitar latches) ---------
        vga_r           = 8'h00;
        vga_g           = 8'h00;
        vga_b           = 8'h00;

        seg_A_lbl       = 7'd0;
        seg_B_lbl       = 7'd0;

        dx_mul          = 0;
        dy_mul          = 0;
        is_plus_seg_mul = 1'b0;
        is_diag_seg_mul = 1'b0;

        dx_div          = 0;
        dy_div          = 0;

        segA            = 7'd0;
        segB            = 7'd0;
        segSUM          = 7'd0;
        segSUB          = 7'd0;
        segMUL          = 7'd0;
        segDIV          = 7'd0;

        // --------------------------------------------------------
        // Si no hay video_on: fondo negro ya está asignado arriba
        // --------------------------------------------------------
        if (!video_on) begin
            // nada más que hacer, ya dejamos todo en 0
        end else begin
            // Fondo blanco en la zona visible
            vga_r = 8'hFF;
            vga_g = 8'hFF;
            vga_b = 8'hFF;

            // ------------------------------------------------
            // Franja de "título" (zona gris arriba)
            // ------------------------------------------------
            if (in_rect(x, y, 0, 640, 20, 70)) begin
                vga_r = 8'hE0;
                vga_g = 8'hE0;
                vga_b = 8'hE0;
            end

            // ------------------------------------------------
            // Labels A y B como dígitos tipo 7-seg
            // ------------------------------------------------
            seg_A_lbl = hex_to_segs(4'hA);
            seg_B_lbl = hex_to_segs(4'hB);

            if (digit_pixel(x, y, COL0_X, LABEL_Y, seg_A_lbl) ||
                digit_pixel(x, y, COL1_X, LABEL_Y, seg_B_lbl)) begin
                vga_r = 8'h00;
                vga_g = 8'h00;
                vga_b = 8'h00;
            end

            // ------------------------------------------------
            // Labels operadores: +, -, *, /
            // ------------------------------------------------

            // "+"
            if ( in_rect(x, y, CX_PLUS-2,  CX_PLUS+2,  CY_OPS-15, CY_OPS+15) || // vertical
                 in_rect(x, y, CX_PLUS-12, CX_PLUS+12, CY_OPS-2,  CY_OPS+2) ) begin // horizontal
                vga_r = 8'h00;
                vga_g = 8'h00;
                vga_b = 8'h00;
            end

            // "-"
            if ( in_rect(x, y, CX_MINUS-12, CX_MINUS+12, CY_OPS-2, CY_OPS+2) ) begin
                vga_r = 8'h00;
                vga_g = 8'h00;
                vga_b = 8'h00;
            end

            // "*": cruz + diagonales
            dx_mul = $signed(x) - $signed(CX_MUL);
            dy_mul = $signed(y) - $signed(CY_OPS);

            is_plus_seg_mul =
                in_rect(x, y, CX_MUL-2,  CX_MUL+2,  CY_OPS-15, CY_OPS+15) ||
                in_rect(x, y, CX_MUL-15, CX_MUL+15, CY_OPS-2,  CY_OPS+2);

            is_diag_seg_mul =
                ((dy_mul + dx_mul) > -3 && (dy_mul + dx_mul) < 3 && dy_mul > -15 && dy_mul < 15) ||
                ((dy_mul - dx_mul) > -3 && (dy_mul - dx_mul) < 3 && dy_mul > -15 && dy_mul < 15);

            if (is_plus_seg_mul || is_diag_seg_mul) begin
                vga_r = 8'h00;
                vga_g = 8'h00;
                vga_b = 8'h00;
            end

            // "/": diagonal
            dx_div = $signed(x) - $signed(CX_DIV);
            dy_div = $signed(y) - $signed(CY_OPS);

            if ((dy_div + dx_div) > -3 && (dy_div + dx_div) < 3 && dy_div > -20 && dy_div < 20) begin
                vga_r = 8'h00;
                vga_g = 8'h00;
                vga_b = 8'h00;
            end

            // ------------------------------------------------
            // Dígitos grandes debajo de cada símbolo:
            // A, B, suma, resta, mul, div
            // ------------------------------------------------
            segA   = hex_to_segs(A_nib);
            segB   = hex_to_segs(B_nib);
            segSUM = hex_to_segs(sum_nib);
            segSUB = hex_to_segs(sub_nib);
            segMUL = hex_to_segs(mul_nib);
            segDIV = hex_to_segs(div_nib);

            if (digit_pixel(x, y, COL0_X, DIGIT_Y, segA)   ||
                digit_pixel(x, y, COL1_X, DIGIT_Y, segB)   ||
                digit_pixel(x, y, COL2_X, DIGIT_Y, segSUM) ||
                digit_pixel(x, y, COL3_X, DIGIT_Y, segSUB) ||
                digit_pixel(x, y, COL4_X, DIGIT_Y, segMUL) ||
                digit_pixel(x, y, COL5_X, DIGIT_Y, segDIV)) begin
                vga_r = 8'h00;
                vga_g = 8'h00;
                vga_b = 8'h00;
            end
        end
    end

endmodule
