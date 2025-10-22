// ============================================================
// ram_data.sv
// Memoria RAM para CPU ARMv4 mínima
// ============================================================
module ram_data #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic wr_en,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data
);

    // Memoria RAM simple
    logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Escritura sincrónica
    always_ff @(posedge clk) begin
        if (wr_en)
            mem[addr] <= wr_data;
    end

    // Lectura combinacional
    assign rd_data = mem[addr];

endmodule
