// Converts the given number to a new number within the interval 0-8
//
// NOTE: given number must be < 2^16

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module tuner(
	input [15:0] num,
	output [16:0] tuned_num
	);

	localparam [16:0] piece = 17'd65536 / 17'd9;
	assign tuned_num = (num >= 17'd65529) ? 17'd8 : num / piece;	
endmodule
