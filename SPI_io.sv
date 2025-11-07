module SPI_io (
    input logic rst,
                mosi,
                sck,
                req,
                ss,
	output logic 	    ack,
	output logic [3:0]	master_data_register
);
	// Estados FSM 0-5
	function automatic logic [5:0] one_hot(int index);
		return (1 << index);
	endfunction

	// current-state, next-state, master-data
	logic [5:0] cs, ns;
	logic [3:0] md;
	
	localparam		S0 = one_hot(0),
						S1 = one_hot(1),
						S2 = one_hot(2),
						S3 = one_hot(3),
						S4 = one_hot(4),
						S5 = one_hot(5);
	
	always_ff @(posedge sck or negedge rst) begin
		if (~rst) begin
			cs <= S0;
			md <= 4'b0;
		end
		else if (~req) cs <= S0;
		else if (~ss) md <= {md[2:0], mosi};
		else if (req) cs <= ns;
	end
	
	assign ns[0] = mosi && (cs[5] || cs[2] || cs[1] || cs[0]);
	assign ns[1] = ~mosi && (cs[0] || cs[4] || cs[5]);
	assign ns[2] = ~mosi && cs[1];
	assign ns[3] = ~mosi && (cs[2] || cs[3]);
	assign ns[4] = mosi && cs[3];
	assign ns[5] = mosi && cs[4];
	assign ack = cs[5];
	assign master_data_register = md;
	
endmodule