fifo_line_buffer	fifo_line_buffer_inst (
	.aclr ( aclr_sig ),
	.clock ( clock_sig ),
	.data ( data_sig ),
	.rdreq ( rdreq_sig ),
	.wrreq ( wrreq_sig ),
	.q ( q_sig ),
	.usedw ( usedw_sig )
	);
