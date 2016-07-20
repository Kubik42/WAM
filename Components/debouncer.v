// Cleans up key bounce

`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "D_flip_flop.v"

module deboncer(
	input [2:0] column,
	input clk, 
	output key_down
	);

	wire key_signal;
	assign key_signal = ~&column;

	wire [2:0] Q;

	// 3-bit register. Once all outputs are high, then the key has been pressed
	dff F0(.data(key_signal),
				 .clk(clk),
				 .reset(1'b1),
				 .Q(Q[0]));

	dff F0(.data(Q[0]),
				 .clk(clk),
				 .reset(1'b1),
				 .Q(Q[1]));

	dff F0(.data(Q[1]),
				 .clk(clk),
				 .reset(1'b1),
				 .Q(Q[2]));

	assign key_down = key_signal & Q[0] & Q[1] & Q[2];
endmodule
