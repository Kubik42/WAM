`timescale 1ns / 1ns // `timescale time_unit/time_precision

module clock_divider(
	input [27:0] counter_max, 
	input clk, 
	input enable, 
	input reset, 
	output reg [27:0] counter);

	// Counting down
	always @(posedge clk or negedge reset)
	begin
		if (~reset)
			counter <= 0;
		else if (enable)
		begin		
			if (counter == 28'd0)  // Counter reached 0
				counter <= counter_max;
			else
				counter <= counter - 1;
		end
	end
endmodule