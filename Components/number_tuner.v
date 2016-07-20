// Converts the given number to a new number within a given interval inclusively
//
// NOTE: given number must be <= 2^16

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module tuner(
	input [4:0] power,
	input [15:0] num,
	input [15:0] min,
	input [15:0] max,
	output [15:0] tuned_num
	);

	wire [15:0] total = max - min;  // Total possibles numbers
	wire [15:0] piece = ({16'd2}**power) / total;  // total*piece = 2^power
	assign tuned_num = (({16'd2}**power) >= num) ? (num / piece) + min : 16'd0;
endmodule
