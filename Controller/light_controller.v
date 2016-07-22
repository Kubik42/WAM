// LED controller

`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "../Components/random_number_generator.v"
`include "../Components/simple_number_tuner.v"
`include "../Components/clock_divider.v"

module light_controller(
	input [27:0] time_on,       // Time a light will stay on for
	input [27:0] time_between,  // Time between flicks
	input load_seed,			// Seed for rng
	input start,				// Signal to start flicking lights
	input clk,
	input reset,
	output reg [8:0] lights,	// Light signals to the board
	output [3:0] light_pos  	// Light position on board
	);

	wire [27:0] counter_btwn;  // Time left until the next light flick
	wire [27:0] counter_on;    // Time left until a light will turn off
	
	reg change_light, light_off, enable_btwn, enable_on; // Light status (ON/OFF)

	reg [1:0] current_state, next_state;

	localparam WAIT_BTWN = 2'd0,  // Wait until turning on light
			   FLICK     = 2'd1,  // Turn on light
			   WAIT_ON   = 2'd2;  // Keep light on

	always @(*)
	begin: state_table
		case (current_state)
			WAIT_BTWN: next_state = (counter_btwn == 28'd0) ? FLICK : WAIT_BTWN;
			FLICK: next_state = WAIT_ON;
			WAIT_ON: next_state = (counter_on == 28'd0) ? WAIT_BTWN : WAIT_ON;
		endcase
	end

	always @(*)
	begin: light_enable
		// By default
		change_light = 1'b0;
		light_off = 1'b0;
		enable_btwn = 1'b0;
		enable_on = 1'b0;

		case (current_state)
			WAIT_BTWN: begin  // Wait until turning on the next light
				change_light = 1'b0;
				light_off = 1'b1;
				enable_btwn = start;
				enable_on = 1'b0;
			end
			FLICK: begin  // Take from rng and turn on light
				change_light = 1'b1;
				light_off = 1'b0;
				enable_btwn = 1'b0;
				enable_on = 1'b0;
			end
			WAIT_ON: begin  // Keep light on
				change_light = 1'b0;
				light_off = 1'b0;
				enable_btwn = 1'b0;
				enable_on = start;
			end
		endcase
	end

	// Frequency divider for turning lights on
	clock_divider FD_BTWN(.counter_max(time_between),
						  .clk(clk), 
						  .enable(enable_btwn),
						  .reset(reset),
						  .counter(counter_btwn));

	// Frequency divider for keeping lights on
	clock_divider FD_ON(.counter_max(time_on),
						.clk(clk), 
						.enable(enable_on),
						.reset(reset),
						.counter(counter_on));

	// Light generation --------------------------------------------------------

	// Lights
	wire [15:0] rand_num;  // 16-bit randomly generated number
	wire [16:0] light;     // Light on board

	// 16-bit random number generator
	rng RNG(.seed(16'd1),  // NEED A BETTER SEED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			.load(load_seed),
			.clk(clk), 
			.reset(reset), 
			.num(rand_num));

	// 0-8 number tuner
	tuner TUNER(.num(rand_num),
				.tuned_num(light));

	// Light control -----------------------------------------------------------
	
	assign light_pos = light[3:0];
	
	always @(posedge clk or negedge reset)
	begin: Flick
		if (~reset)  begin  // Turn off all lights			
			lights <= 0;
			current_state <= WAIT_BTWN;
		end
		else begin
			if (change_light) begin  // Turn on a light
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

			if (light_off) begin  // Turn off a light
				lights <= 0;
			end
			current_state <= next_state;
		end
	end
endmodule
