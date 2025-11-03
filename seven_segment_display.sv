module seven_segment_display (
    input  logic [3:0] sev_seg_in,  
    output logic [6:0] sev_seg_out
);
    always_comb begin
        case (sev_seg_in)
            4'b0000: sev_seg_out = 7'b0000001; // 0
            4'b0001: sev_seg_out = 7'b1001111; // 1
            4'b0010: sev_seg_out = 7'b0010010; // 2
            4'b0011: sev_seg_out = 7'b0000110; // 3
            4'b0100: sev_seg_out = 7'b1001100; // 4
            4'b0101: sev_seg_out = 7'b0100100; // 5
            4'b0110: sev_seg_out = 7'b0100000; // 6
            4'b0111: sev_seg_out = 7'b0001111; // 7
            4'b1000: sev_seg_out = 7'b0000000; // 8
            4'b1001: sev_seg_out = 7'b0000100; // 9
            4'b1010: sev_seg_out = 7'b0001000; // A
            4'b1011: sev_seg_out = 7'b1100000; // b
            4'b1100: sev_seg_out = 7'b0110001; // C
            4'b1101: sev_seg_out = 7'b1000010; // d
            4'b1110: sev_seg_out = 7'b0110000; // E
            4'b1111: sev_seg_out = 7'b0111000; // F
            default: sev_seg_out = 7'b1111111; // Apagado
        endcase
    end

endmodule