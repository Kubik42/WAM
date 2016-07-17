// D Flip Flop

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module dff(
	input data
	input clk
	input reset
	output q
	);

	reg q;

	always @(posedge clk or negedge reset) begin
		if (~reset)
			q <= 1'b0;
		else
			q <= data;
	end
endmodule
