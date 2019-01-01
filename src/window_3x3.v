module window_3x3(
						input 			  	clock,
						input 			  	frame_reset,
						
						input	  [7:0] 	datain,
						input 			  	datain_en,

						output reg[7:0] 	data00,
						output reg[7:0] 	data01,
						output reg[7:0] 	data02,
						
						output reg[7:0] 	data10,
						output reg[7:0] 	data11,
						output reg[7:0] 	data12,
						
						output reg[7:0] 	data20,
						output reg[7:0] 	data21,
						output reg[7:0] 	data22,
						
						output reg		  	data_valid
						);
						
	parameter PIX_PER_LINE = 320;
	parameter PIX_DOUBLE_LINE = 640;
	
	reg 		  	line_buf_rden;
	reg 		  	line_buf_rden_d1;
	wire[7:0] 		line_buf_dout;
	wire[7:0] 		line_dout00;
	wire[7:0] 		line_dout01;
	wire[9:0]  		line_buf_data_count;
	wire[9:0]  		line_data_count00;
	wire[9:0]  		line_data_count01;
	wire		  	line_rden0;
	wire		  	line_rden1;
	reg[9:0]   		line_buf_rd_cnt;
	reg[10:0]  		line_rden_cnt;
	reg		  		line_data_valid;
	reg		  		line_data_valid_d1,line_data_valid_d2;
	
	assign line_rden0 = (line_data_count00 >= PIX_PER_LINE - 1) ? line_buf_rden : 1'b0;
	assign line_rden1 = (line_data_count01 >= PIX_PER_LINE - 1) ? line_buf_rden : 1'b0;
	
	always @(posedge clock)
	begin
		if(frame_reset)
			line_buf_rden <= 1'b0;
		else if(line_buf_data_count >= PIX_PER_LINE)
			line_buf_rden <= 1'b1;
		else if(line_buf_rd_cnt == PIX_PER_LINE - 1)
			line_buf_rden <= 1'b0;
	end
	
	always @(posedge clock)
	begin
		if(frame_reset)
			line_buf_rd_cnt <= 10'd0;
		else if(line_buf_rden)
			line_buf_rd_cnt <= line_buf_rd_cnt + 1'b1;
		else
			line_buf_rd_cnt <= 10'd0;
	end
	
	always @(posedge clock)
	begin
		line_buf_rden_d1 <= line_buf_rden;
	end
	
	always @(posedge clock)
	begin
		if(frame_reset)
			line_rden_cnt <= 11'd0;
		else if(line_buf_rden) begin
			if(line_rden_cnt < PIX_DOUBLE_LINE)
				line_rden_cnt <= line_rden_cnt + 1'b1;
			else
				line_rden_cnt <= line_rden_cnt;
		end
		else
			line_rden_cnt <= line_rden_cnt;
	end
	
	always @(posedge clock)
	begin
		if(frame_reset)
			line_data_valid <= 1'b0;
		else if(line_rden_cnt == PIX_DOUBLE_LINE)
			line_data_valid <= line_buf_rden;
		else
			line_data_valid <= 1'b0;
	end
	
	always @(posedge clock)
	begin
		if(frame_reset) begin
			data00 <= 8'h0;
			data01 <= 8'h0;
			data02 <= 8'h0;
			
			data10 <= 8'h0;
			data11 <= 8'h0;
			data12 <= 8'h0;
			
			data20 <= 8'h0;
			data21 <= 8'h0;
			data22 <= 8'h0;
			
			line_data_valid_d1 <= 1'b0;
			line_data_valid_d2 <= 1'b0;
		end
		else begin
			data22 <= line_buf_dout;
			data21 <= data22;
			data20 <= data21;
			
			data12 <= line_dout00;
			data11 <= data12;
			data10 <= data11;
			
			data02 <= line_dout01;
			data01 <= data02;
			data00 <= data01;
			
			line_data_valid_d1 <= line_data_valid;
			line_data_valid_d2 <= line_data_valid_d1;
			data_valid			 <= line_data_valid_d2;
		end
	end	
	
	fifo_line_buffer line_buf(
		.aclr		(frame_reset),
		.clock		(clock),
		.data		(datain),
		.rdreq		(line_buf_rden),
		.wrreq		(datain_en),
		.q			(line_buf_dout),
		.usedw		(line_buf_data_count)
		);
	
	fifo_line_buffer line_00(
		.aclr		(frame_reset),
		.clock		(clock),
		.data		(line_buf_dout),
		.rdreq		(line_rden0),
		.wrreq		(line_buf_rden_d1),
		.q			(line_dout00),
		.usedw		(line_data_count00)
		);
	
	fifo_line_buffer line_01(
		.aclr		(frame_reset),
		.clock		(clock),
		.data		(line_dout00),
		.rdreq		(line_rden1),
		.wrreq		(line_buf_rden_d1),
		.q			(line_dout01),
		.usedw		(line_data_count01)
		);
								  
endmodule 