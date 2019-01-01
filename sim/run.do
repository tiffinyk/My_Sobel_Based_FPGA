#---------  ------------#

#1.exit modelsim simulation
quit -sim

#2.clear messages
.main clear

#3.delete the existing work dir
# if [file exists work] {vdel -all}

#--------- create library and mapping ------------#
#4.creat work dir
vlib work

#5.
vmap work work

#6.complie .v files
vlog -work work ./tb_x.v
vlog -work work ./../src/window_3x3.v
vlog -work work ./../src/sobel.v
# vlog -work work ./quartus_lib/220model.v
vlog -work work ./quartus_lib/altera_mf.v
# vlog -work work ./../core/core_shift_ram/core_shift_ram.v
vlog -work work ./../core/fifo_line_buffer/fifo_line_buffer.v

#7.start simulation
vsim -voptargs=+acc work.tb_x

#8.add waves
	#add -divider { name }
add wave -group tb_x -radix unsigned tb_x/*
add wave -group window_3x3 -radix unsigned tb_x/inst_window_3x3/*

add wave -group check -radix unsigned tb_x/inst_window_3x3/datain
add wave -group check -radix unsigned tb_x/inst_window_3x3/data00
add wave -group check -radix unsigned tb_x/inst_window_3x3/data01
add wave -group check -radix unsigned tb_x/inst_window_3x3/data02
add wave -group check -radix unsigned tb_x/inst_window_3x3/data10
add wave -group check -radix unsigned tb_x/inst_window_3x3/data11
add wave -group check -radix unsigned tb_x/inst_window_3x3/data12
add wave -group check -radix unsigned tb_x/inst_window_3x3/data20
add wave -group check -radix unsigned tb_x/inst_window_3x3/data21
add wave -group check -radix unsigned tb_x/inst_window_3x3/data22
add wave -group check -radix unsigned tb_x/inst_window_3x3/data_valid
#9.run
run 13ms