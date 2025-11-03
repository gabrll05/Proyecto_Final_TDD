// ============================================================
// rom_program.sv
// ROM de programa con carga desde archivo HEX
// ============================================================
module rom_program(
    input  logic [7:0] addr,
    output logic [31:0] data
);
    logic [31:0] memory [0:255];

    initial begin
        $readmemh("program_mem.hex", memory);
    end

    assign data = memory[addr];
endmodule
