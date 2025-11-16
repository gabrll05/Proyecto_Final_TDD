// ============================================================
// vga_controller.sv
// Wrapper de timing VGA 640x480@60Hz (25 MHz pixel clock aprox)
// Solo genera hsync, vsync, video_on, x, y
// ============================================================
module vga_controller #(
    parameter int H_ACTIVE = 640,
    parameter int V_ACTIVE = 480,
    parameter int H_FP  = 16,
    parameter int H_SYNC= 96,
    parameter int H_BP  = 48,
    parameter int V_FP  = 10,
    parameter int V_SYNC= 2,
    parameter int V_BP  = 33,
    parameter bit HS_POL= 1'b0,
    parameter bit VS_POL= 1'b0
)(
    input  logic        clk_pix,
    input  logic        rst,
    output logic        hsync,
    output logic        vsync,
    output logic        video_on,
    output logic [11:0] x,
    output logic [11:0] y
);

    vga_timing #(
        .H_ACTIVE(H_ACTIVE), .V_ACTIVE(V_ACTIVE),
        .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP),
        .V_FP(V_FP), .V_SYNC(V_SYNC), .V_BP(V_BP),
        .HS_POL(HS_POL), .VS_POL(VS_POL)
    ) u_timing (
        .clk_pix (clk_pix),
        .rst     (rst),
        .hsync   (hsync),
        .vsync   (vsync),
        .video_on(video_on),
        .x       (x),
        .y       (y),
        .line_tick(),
        .frame_tick()
    );

endmodule
