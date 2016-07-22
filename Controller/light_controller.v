// LED controller

`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "../Components/random_number_generator.v"
`include "../Components/simple_number_tuner.v"
`include "../Components/clock_divider.v"
// `include "Components/random_number_generator.v"
// `include "Components/number_tuner.v"
// `include "Components/clock_divider.v"

module light_controller(
	input [27:0] light_on,       // Time a light will stay on for
	input [27:0] light_between,  // Time between flicks
	input load_seed,
	input clk,
	input reset,
	output reg [8:0] lights,
	output reg [3:0] position // Position of the LED that is on (0-8)
	);

	// Lights
	wire [15:0] rand_num;  // 16-bit randomly generated number
	wire [16:0] light;     // light on board

	// Time between subsequent light flicks
	wire [27:0] counter_btwn;

	// Time the light will stay on for
	wire [27:0] counter_on;
	
	// A light should be on or off 
	wire light_onoff;

	// Frequency divider for turning lights on
	clock_divider FD_BTWN(.counter_max(light_between),
						  .clk(clk), 
						  .enable(~light_onoff),
						  .reset(reset),
						  .counter(counter_btwn));

	// Turn off FD_BTWN and power FD_ON
	assign light_onoff = (counter_btwn == 28'd0) ? 1 : 0;

	// Frequency divider for keeping lights on
	clock_divider FD_ON(.counter_max(light_on),
						.clk(clk), 
						.enable(light_onoff),
						.reset(reset),
						.counter(counter_on));

	// Turn off FD_ON and power FD_BTWN
	assign light_onoff = (counter_on == 28'd0) ? 0 : 1;

	// Light generation --------------------------------------------------------

	// 16-bit random number generator
	rng RNG(.seed(16'b1), 
			.load(load_seed), 
			.clk(clk), 
			.reset(reset), 
			.num(rand_num));

	// 0-8 number tuner
	tuner TUNER(.num(rand_num),
				.tuned_num(light));

	// ----------------=--------------------------------------------------------
	
	assign position = light[3:0]; 
	
	always @(posedge clk or negedge reset)
	begin: Flick
		if (~reset)  begin  // Turn off all lights			
			lights <= 0;
			counter_btwn <= light_between;
			counter_on <= light_on;
			light_onoff <= 1'b0;
		end
		else if (light_onoff) begin  // Turn on a light
			case (light[3:0])
				4'd0: lights[0] <= 1'b1;
				4'd1: lights[1] <= 1'b1;
				4'd2: lights[2] <= 1'b1;
				4'd3: lights[3] <= 1'b1;
				4'd4: lights[4] <= 1'b1;
				4'd5: lights[5] <= 1'b1;
				4'd6: lights[6] <= 1'b1;
				4'd7: lights[7] <= 1'b1;
				4'd8: lights[8] <= 1'b1;
			endcase
		end
		else if (~light_onoff) begin  // Turn off a light
			lights <= 0;
		end
	end
endmodule
