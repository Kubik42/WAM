// Combines row and column

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module keyreg(
	input [3:0] pressed,
	input clk,
	input reset,
	output reg [3:0] key
	);

	always @(posedge clk or negedge reset) begin
		if (~reset)
			key <= 4'b0;
		else
			key <= pressed;
	end
endmodule
