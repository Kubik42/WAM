`timescale 1ns / 1ns // `timescale time_unit/time_precision

// Fibonacci LFSR random number generator (generates a number between 0 and 8)
module lfsr(clk, reset, enable, rndnum);
	input clk, reset, enable;
	output reg [3:0] rndnum;			// a random number between 0 and 8
	 
	reg [15:0] random;
	reg [2:0] count; 				// keep track of the shifts
	wire feedback = random[15] ^ random[14] ^ random[12] ^ random[3];
	
	always @(posedge clk or negedge reset)
		begin
 			if (!reset)
 				begin
  					random <= 15'b000_000_000_000_001; 	// cannot reset to 0
  					count <= 3'd0;
 				end
 			else if(enable)
 				begin
  					random <= {random[14:0], feedback}; //shift left every clock pulse
  					count <= count + 1'b1;
 				end
		end
	always @(*)
		begin
 			if (count == 3'd4)					// 4 new digits are generated
 				begin
  					count <= 3'd0;
  					if (~random[15]) 			// the first digit is not 1
  						rndnum <= random[15:12]; 
  					else if (~|random[14:12]) 	// the first digit is 1 but followed by 0s
  						rndnum <= random[15:12]; 
 				end
		end
endmodule
