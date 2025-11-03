module top_fpga_cpu_test(
    input  logic CLOCK_50,
    input  logic [0:0] KEY,
    output logic [9:0] LEDR
);
    logic rst_n;
    assign rst_n = KEY[0];

    logic [31:0] result;

    cpu_armv4 u_cpu (
        .clk(CLOCK_50),
        .reset(~rst_n),
        .alu_result_out(result)
    );

    assign LEDR = result[9:0];
endmodule
