// LED controller

`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "Components/random_number_generator.v"
`include "Components/number_tuner.v"
`include "Components/clock_divider.v"

module light_controller(
	input CLOCK_50,
	output reg [8:0] lights
	);

	// Frequency divider for turning lights on
	clock_divider FD_BTWN(.counter_max(light_between)
						  .clk(CLOCK_50), 
						  .enable(~turn_on_light),
						  .reset(reset),
						  .counter(counter_btwn));

	// Turn off FD_BTWN and power FD_ON
	assign turn_on_light = (counter_btwn == 28'd0) ? 1 : 0;
	assign turn_off_light = (counter_btwn == 28'd0) ? 1: 0;

	// Frequency divider for keeping lights on
	clock_divider FD_ON(.counter_max(light_on)
						.clk(CLOCK_50), 
						.enable(turn_off_light),
						.reset(reset),
						.counter(counter_on));

	// Turn off FD_ON and power FD_BTWN
	assign turn_off_light = (counter_on == 28'd0) ? 0 : 1;
	assign turn_on_light = (counter_on == 28'd0) ? 0 : 1;

	// 16-bit random number generator
	rng RNG(.seed(16'b0), 
			.load(1'b0), 
			.clk(CLOCK_50), 
			.reset(reset), 
			.num(rand_num));

	// 0-8 number tuner
	tuner TUNER(.power(5'd16),  // 2^16
				.num(rand_num),
				.min(16'd0),  // 0
				.max(16'd8),  // 8
				.tuned_num(light));

	always @(posedge CLOCK_50 or negedge reset)
	begin: Flick
		if (~reset)  begin  // Turn off all lights, reset all counters					
			lights <= 0;
			counter_btwn <= light_between;
			turn_on_light <= 1'b0;
			counter_on <= light_on;
			turn_off_light <= 1'b0;
		end
		else if (turn_on_light) begin  // Turn on a light
			case (light)
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
		else if (turn_on_light) begin  // Turn off a light
			lights <= 0;
		end
	end
endmodule
