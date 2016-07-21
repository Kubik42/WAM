// Fibonacci LFSR based 16-bit ranbom number generator

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module rng(
	input [15:0] seed,
	input load,
	input clk,
	input reset,
	output reg [15:0] num
	);

	reg [15:0] LFRS_reg;
	reg [3:0] count;

	// Taps taken from Table 3 http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
	wire feedback;
	assign feedback = LFRS_reg[15] ^ LFRS_reg[14] ^ LFRS_reg[12] ^ LFRS_reg[3];
	
	always @(posedge clk or negedge reset) begin
		if (~reset) begin  // DO NOT RESET THE SEED
			count <= 4'd0;
		end
		else begin
			if (load)
				LFRS_reg <= seed;
			else begin
				LFRS_reg <= {LFRS_reg[14:0], feedback};  // Shift
				count <= count + 1'b1;

				if (count == 15) begin
					count <= 4'd0;  // Resetting counter
					num <= LFRS_reg;
				end
			end
		end
	end
endmodule
