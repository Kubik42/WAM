// two digit 6-bit binary to decimal decoder 

`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "bin_dec_decoder.v"

module two_digit_decoder(
	input [5:0] b,
	input reset,
 	output [6:0] hex0,
 	output [6:0] hex1
 	);
 	
 	wire [3:0] r; 			// right digit (0-9)
 	wire[3:0] l;			
	
	assign l[3] = 1'b0;
	assign l[2] = b[5] & b[3] | b[5] & b[4];
	assign l[1] = ~b[5] & b[4] & b[2] | ~b[5] & b[4] & b[3] | b[4] & b[3] & b[2] | b[5] & ~b[4] & ~b[3];
	assign l[0] = ~b[5] & ~b[4] & b[3] & b[1] | ~b[5] & ~b[4] & b[3] & b[2] | ~b[5] & b[3] & b[2] & b[1] | ~b[5] & b[4] & ~b[3] & ~b[2] | b[5] & ~b[4] & ~b[3] | b[5] & ~b[3] & b[1] | b[5] & ~b[3] & b[2] | b[5] & b[4] & b[3] & ~b[2];
	assign r[3] = ~b[5] & ~b[4] & b[3] & ~b[2] & ~b[1] | ~b[5] & b[4] & ~b[3] & ~b[2] & b[1] | ~b[5] & b[4] & b[3] & b[2] & ~b[1] | b[5] & ~b[4] & ~b[3] & b[2] & b[1] | b[5] & b[4] & ~b[3] & ~b[2] & ~b[1] | b[5] & b[4] & b[3] & ~b[2] & b[1];
	assign r[2] = ~b[5] & ~b[4] & ~b[3] & b[2] | ~b[4] & ~b[3] & b[2] & ~b[1] | ~b[4] & b[3] & b[2] & b[1] | ~b[5] & b[4] & ~b[2] & ~b[1] | ~b[5] & b[4] & b[3] & ~b[2] | b[4] & b[3] & ~b[2] & ~b[1] | b[5] & ~b[4] & ~b[3] & ~b[2] & b[1] | b[5] & ~b[4] & b[3] & b[2] | b[5] & b[4] & ~b[3] & b[2] & b[1];
	assign r[1] = ~b[5] & ~b[4] & ~b[3] & b[1] | ~b[5] & ~b[3] & b[2] & b[1] | ~b[5] & ~b[4] & b[3] & b[2] & ~b[1] | ~b[5] & b[4] & ~b[3] & ~b[2] & ~b[1] | ~b[5] & b[4] & b[3] & ~b[2] & b[1] | b[5] & ~b[4] & ~b[3] & ~b[1] | b[5] & ~b[3] & b[2] & ~b[1] | b[5] & ~b[4] & b[3] & b[1] | b[5] & b[4] & b[3] & ~b[2] & ~b[1];
	assign r[0] = b[0] | b[5] & b[4] & b[3] & b[2] & b[1];
 	
 	bdd h0(.binary(r),
 			.reset(reset),
 			.hex(hex0));
 			
 	bdd h1(.binary(l),
 			.reset(reset),
 			.hex(hex1));
endmodule
