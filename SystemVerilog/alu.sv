// ---------------------------------------------
// ALU única (nombre: alu) con NZCV internos
// ---------------------------------------------
module alu (
    input  logic [3:0]  op,        // 1=ADD, 2=SUB, 0=NOP/uops
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    // Flags internas (la CPU actual no las usa)
    logic n, z, c, v;

    // Señales internas para carry/borrow
    logic [32:0] sum_ext, diff_ext;

    always_comb begin
        // defaults
        y = 32'd0;
        c = 1'b0;
        v = 1'b0;

        unique case (op)
            4'd0: begin
                // NOP/uop para microestados de MEM/branch, etc.
                y = 32'd0;
                c = 1'b0;
                v = 1'b0;
            end

            4'd1: begin // ADD
                sum_ext = {1'b0, a} + {1'b0, b};
                y = sum_ext[31:0];
                c = sum_ext[32];                     // carry out
                v = (a[31] == b[31]) && (y[31] != a[31]); // overflow (signed)
            end

            4'd2: begin // SUB = A - B   (ARM: C = ~borrow)
                diff_ext = {1'b0, a} + {1'b0, ~b} + 33'd1;
                y = diff_ext[31:0];
                c = diff_ext[32];                    // ~borrow
                v = (a[31] != b[31]) && (y[31] != a[31]);
            end

            default: begin
                y = 32'd0;
                c = 1'b0;
                v = 1'b0;
            end
        endcase

        n = y[31];
        z = (y == 32'd0);
    end

`ifdef SIM
    // Mensajes para que tu log quede igual al que vienes usando
    always_comb begin
        if (op == 4'd1)
            $display("ALU: ADD %0d + %0d = %0d @t=%0t", a, b, y, $time);
        else if (op == 4'd2)
            $display("ALU: SUB %0d - %0d = %0d @t=%0t", a, b, y, $time);
        else
            $display("ALU: OP=%0d A=%0d B=%0d -> Y=%0d @t=%0t", op, a, b, y, $time);
    end
`endif
endmodule
