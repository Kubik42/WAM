// Converts the given number to a new number within a given interval
//
// NOTE: given number must be <= 2^128

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module tuner(
	input [6:0] power,
	input [127:0] number,
	input [127:0] min,
	input [127:0] max,
	output [127:0] tunedNumber
	);

	wire [127:0] total = max - min + 1;  // Total possibles numbers
	wire [127:0] piece = ({128'd2}**power) / total;  // total*piece = 2^power
	assign tunedNumber = (({128'd2}**power) >= number) ? number / piece : 128'd0;
endmodule
