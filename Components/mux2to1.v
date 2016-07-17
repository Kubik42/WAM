// 2 to 1 mux

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module mux2to1(
	input x, 
	input y, 
	input select, 
	output m
	);
  
    assign m = select & y | ~select & x;
endmodule
