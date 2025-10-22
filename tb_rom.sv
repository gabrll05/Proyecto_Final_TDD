`timescale 1ns/1ps
module tb_rom;
    logic [7:0] addr;
    logic [31:0] data;

    rom_program uut (.addr(addr), .data(data));

    initial begin
        $display("=== Test ROM de Programa ===");
        addr = 0; #10;
        repeat (8) begin
            $display("Addr %0d -> %h", addr, data);
            addr = addr + 1;
            #10;
        end
        $stop;
    end
endmodule
