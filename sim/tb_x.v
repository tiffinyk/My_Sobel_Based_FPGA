/*-----------------------------------------------------------------------
CONFIDENTIAL IN CONFIDENCE
This confidential and proprietary software may be only used as authorized
by a licensing agreement from zjl ().
In the event of publication, the following notice is applicable:
Copyright (C) 2013-20xx zjl Corporation
The entire notice above must be reproduced on all authorized copies.
Author				:		zjl
Technology blogs 	:
Email Address 		: 		540113104@gmail.com
Filename			:		.v
Data				:		2018-04-06
Description			:		.
Modification History	:
Data			By			Version			Change Description
=========================================================================
04/06/18		zjl			  1.0				Original
-----------------------------------------------------------------------*/

`timescale 1ns/1ns
module tb_x;

//------------------------------------------
localparam PERIOD_50MHZ = 20;			//50MHz-20ns
localparam PERIOD_20MS = 20000000;			//50MHz
//信号列表
reg	 				clk;		//clock
reg 				rst_n;		//reset @high voltage
reg					frame_reset;
reg					in_pulse;	//input signal
reg					i_start;	//to streamscale
wire 	[7:0]		o_data;		//data after scale
wire 				o_dvalid;	//data valid after scale
reg 	[9:0] 		cnt_x=0;	//counter for horizne
reg 	[9:0] 		cnt_y=0;	//counter for vertical
reg 				sync_x = 0;	//sync signal for horizne
reg 				sync_y = 0;	//sync signal for vertical
wire 				fifo_wr;
wire 	[7:0]		data_tmp;
// reg 	[0:0]		rand_data;	//random data out
integer 			N = 2;		//random seed
reg 	[7:0] 		reg_mem[0:320*256-1];	//! memory
integer 			addr;				//memory address

reg [7:0]p0;
reg [7:0]p1;
reg [7:0]p2;
reg [7:0]p3;
reg [7:0]p5;
reg [7:0]p6;
reg [7:0]p7;
reg [7:0]p8;
wire [7:0]out;

wire [ 7:0 ]data00;
wire [ 7:0 ]data01;
wire [ 7:0 ]data02;
wire [ 7:0 ]data10;
wire [ 7:0 ]data11;
wire [ 7:0 ]data12;
wire [ 7:0 ]data20;
wire [ 7:0 ]data21;
wire [ 7:0 ]data22;
wire 		data_valid;
//------------------任务------------------------
//*任务：系统初始化
task task_sysinit;
begin
	in_pulse = 0;
	i_start = 0;
end
endtask

//*任务：Generate global reset
task task_reset;
begin
	rst_n = 0;
	repeat(2) @(negedge clk);
	rst_n = 1;
end
endtask

//*任务：读取文件到内存
task load_data2mem;
begin
	$readmemh("lena.txt",reg_mem);
end
endtask

//*任务：读取一行数据
//task功能说明：先延时#(10000*3)，然后在时钟上升沿行计数器加一，重复321次，最后截取计数器1~320周期，共计320个像素
task generate_line;
	begin
		#(10000*4)
		cnt_x = 0;
		repeat(321) begin
			@ ( posedge clk ) begin
				cnt_x = cnt_x + 1;
			end
		sync_x = ( cnt_x >= 10'd1 && cnt_x <= 10'd320 ) ? 1 : 0;
		end
	end
endtask

//*任务：读取一帧数据
task generate_frame;
	begin
		repeat(321) begin//x行数
			generate_line;
		end
	end
endtask

//task of generate random bit signal
//*任务：产生随机数
// task task_rand_bit;
// begin
// 	begin
// 		for( i = 0; i < 255; i=i+1 )begin
// 			@( posedge clk );
// 				rand_data = { $random } % N;//随机数取值范围[0,N-1]
// 		end
// 	end
// end
// endtask
//------------------------------------------

//系统时钟
initial
begin
	clk = 0;
	forever	#(PERIOD_50MHZ/2)
	clk = ~clk;
end
//-----------------存储器地址------------------------
//生成存储器地址
always @ (posedge clk)begin
	if(!rst_n) begin
		addr <= 0;
	end
	else if( sync_x )begin
		addr <= addr +1;
	end
end
assign data_tmp = reg_mem[addr];//从内存中读出数据
//------------------行计数-----------------------
always @ (posedge clk)begin
	if(!rst_n) begin
		cnt_y <= 10'd0;
	end
	else if( cnt_y == 10'd256 )begin
		cnt_y <=  10'd256;
	end
	else if( sync_x && cnt_x == 10'd320 )begin
		cnt_y <= cnt_y +1;
	end
	else
		cnt_y <= cnt_y;
end
always @ (*)begin
	if(!rst_n) begin
		sync_y <= 1'd0;
	end
	else if( cnt_x > 10'd0 && cnt_y< 10'd256 )begin
		sync_y <= 1'd1;
	end
	else if( cnt_y== 10'd256 )begin
		sync_y <= 1'd0;
	end
	else
		sync_y <= sync_y;
end
assign fifo_wr = sync_x && sync_y;//! 同步信号

//----------------------------------------------
initial begin

end
initial
begin
	task_sysinit;
	task_reset;
	#(PERIOD_50MHZ)
	load_data2mem;
	#5000 i_start = 1;
	#(PERIOD_50MHZ*2)
	i_start = 0;
	generate_frame;
	#100
	@ ( posedge clk )
		in_pulse = 1;
	@ ( posedge clk )
		in_pulse = 0;

end
initial
begin

	frame_reset =0;
	#(20000)
	frame_reset =1;
	#(PERIOD_50MHZ)
	frame_reset = 0;
	#(PERIOD_20MS)
	frame_reset =1;
	#(PERIOD_50MHZ)
	frame_reset = 0;	
end
//----------------------系统函数------------------------
//将仿真数据o_data写入外部TXT文件中(x1.txt)
integer file_df;
initial begin
	//文件放置在"工程目录\simulation\modelsim"路径下
	file_df = $fopen("x1.txt");
	if(!file_df)begin
		$display("could not open file!");
		$finish;
	end
end
always @(posedge clk) begin
	if( data_valid )//一帧图像数据
		$fdisplay(file_df,"%d",out);
end

initial begin
	// $dumpfile("test.vcd");
	// $dumpvars();
end

//----------------------------------------------
window_3x3 inst_window_3x3(
			.clock			( clk ),
			.frame_reset	( frame_reset ),
			.datain			( data_tmp ),
			.datain_en		( sync_x ),
			.data00			( data00 ),
			.data01			( data01 ),
			.data02			( data02 ),
			.data10			( data10 ),
			.data11			( data11 ),
			.data12			( data12 ),
			.data20			( data20 ),
			.data21			( data21 ),
			.data22			( data22 ),
			.data_valid		( data_valid )
						);

always @(posedge clk) begin
	if( !rst_n ) begin
		p0 <= 8'd0;
		p1 <= 8'd0;
		p2 <= 8'd0;
		p3 <= 8'd0;
		p5 <= 8'd0;
		p6 <= 8'd0;
		p7 <= 8'd0;
		p8 <= 8'd0;
	end

	else if( data_valid )begin
		p0 <= data00;
		p1 <= data01;
		p2 <= data02;
		p3 <= data10;
		p5 <= data12;
		p6 <= data20;
		p7 <= data21;
		p8 <= data22;
	end
end

sobel inst_sobel( 
	.p0		( p0 ), 
	.p1		( p1 ), 
	.p2		( p2 ), 
	.p3		( p3 ), 
	.p5		( p5 ), 
	.p6		( p6 ), 
	.p7		( p7 ), 
	.p8		( p8 ), 
	.out	( out ) 
	);
endmodule
