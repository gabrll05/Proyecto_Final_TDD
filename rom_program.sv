// ============================================================
// rom_program.sv
// Memoria ROM de programa para CPU ARMv4 mínima
// ============================================================
module rom_program(
    input  logic [7:0] addr,      // dirección del programa
    output logic [31:0] data      // instrucción de salida
);

    // Memoria ROM: 256 instrucciones de 32 bits
    logic [31:0] memory [0:255];

    // Carga inicial desde archivo externo
    initial begin
        $readmemh("program_mem.hex", memory);
    end

    assign data = memory[addr];

endmodule
