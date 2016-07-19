`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "random_number_generator.v"
`include "number_tuner.v"
`include "clock_divider.v"

// KEY[0] - reset
// SW[3:0] - difficulty

module wam(
	input [0:0] KEY,
	input [9:0] SW,
	output [8:0] LEDR
	);

	wire [15:0] rand_num;  // 16-bit randomly generated number
	wire [3:0] light;      // light on board

	reg [27:0] light_between;  // Time between subsequent light flicks
	wire [27:0] counter_btwn;
	wire turn_on_light;

	reg [27:0] light_on;  // Time the light will stay on for
	wire [27:0] counter_on;
	wire turn_off_light;

	always @(*) 
	begin : Difficulty
		case (SW[3:0])
			0001: begin  // Level 1: 2 seconds
				light_between <= 25000000 - 1;
				light_on <= 25000000 - 1;
			end
			0010: begin  // Level 2: 1 second
				light_between <= 50000000 - 1;
				light_on <= 50000000 - 1;
			end
			0100: begin  // Level 3: 0.50 seconds, 1 second countdown
				light_between <= 100000000 - 1;
				light_on <= 50000000 - 1;
			end
			1000: begin  // Level 4: 0.25 seconds, 0.50 second countdown
				light_between <= 200000000 - 1;
				light_on <= 100000000 - 1;
			end
			default: begin  // Same as level 2
				light_between <= 50000000 - 1;
				light_on <= 50000000 - 1;
			end
		endcase
	end

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
			LEDR <= 0;
			counter_btwn <= light_between;
			turn_on_light <= 1'b0;
			counter_on <= light_on;
			turn_off_light <= 1'b0;
		end
		else if (turn_on_light) begin  // Turn on a light
			case (light)
				4'd0: LEDR[0] <= 1'b1;
				4'd1: LEDR[1] <= 1'b1;
				4'd2: LEDR[2] <= 1'b1;
				4'd3: LEDR[3] <= 1'b1;
				4'd4: LEDR[4] <= 1'b1;
				4'd5: LEDR[5] <= 1'b1;
				4'd6: LEDR[6] <= 1'b1;
				4'd7: LEDR[7] <= 1'b1;
				4'd8: LEDR[8] <= 1'b1;
			endcase
		end
		else if (turn_on_light) begin  // Turn off a light
			LEDR <= 0;
		end
	end

endmodule
