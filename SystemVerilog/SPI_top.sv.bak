module SPI_top (
	input logic 	rst,
						mosi,
						sck,
						req,
						ss,
	output logic 	ack,
	output logic [3:0] 	master_data_reg,
	output logic [6:0]	sev_seg_md
);

	SPI_io u_SPI_io (
		.rst(rst),
		.mosi(mosi),
		.sck(sck),
		.req(req),
		.ss(ss),
		.ack(ack),
		.master_data_register(master_data_reg)
	);
	
	seven_segment_display u_sev_seg_d (
		.sev_seg_in(master_data_reg),
		.sev_seg_out(sev_seg_md)
	);
endmodule