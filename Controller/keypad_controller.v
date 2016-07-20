`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "./Components/debouncer.v"
`include "./Components/clock_divider.v"

module keypad_controller(
	input [2:0] column,
	input clk,
	input reset,
	output reg key_down,
	output [2:0] row,
	output [4:0] key 
	);

	debouncer D(.column(column),
				.clk(),
				.key_down(key_down));

endmodule
