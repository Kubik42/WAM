// D Flip Flop

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module dff(
	input data
	input clk
	input reset
	output reg Q
	);

	always @(posedge clk or negedge reset) begin
		if (~reset)
			Q <= 1'b0;
		else
			Q <= data;
	end
endmodule
