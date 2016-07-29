// Combines row and column

`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "key_decoder.v"

module keyreg(
	input [3:0] pressed,
	input clk,
	input reset,
	output reg [3:0] key
	);

	wire [3:0] key_number;

	key_decoder DEC(.key(pressed),
					.key_number(key_number));

	always @(posedge clk or negedge reset) begin
		if (~reset)
			key <= 4'd15;
		else
			key <= key_number;
	end
endmodule
