`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "Controller/light_controller.v"
`include "Controller/keypad_controller.v"

// KEY[0] - reset
// SW[3:0] - difficulty
// SW[9:6] - game mode
// SW[5]   - total game points

module wam(
	input [0:0] KEY,
	input [9:0] SW,
	input CLOCK_50,
	input [2:0] key_matrix_column,
	output reg [8:0] LEDR
	);

	// Basic game settings -----------------------------------------------------------------------------

	// Switches
	wire [3:0] difficulty;
	assign difficulty = SW[3:0]

	wire [3:0] gamemode;
	assign gamemode = SW[9:6];

	// Points
	localparam [4:0] normal_points = 5'd25,    // 25 light flicks
			   [5:0] extended_points = 6'd50;  // 50 light flicks
	reg [5:0] total_points;

	// Lights
	wire [15:0] rand_num;  // 16-bit randomly generated number
	wire [3:0] light;      // light on board

	// Counters/timers
	reg [27:0] light_between;  // Time between subsequent light flicks
	wire [27:0] counter_btwn;
	wire turn_on_light;

	reg [27:0] light_on;  // Time the light will stay on for
	wire [27:0] counter_on;
	wire turn_off_light;

	always @(*) 
	begin : Difficulty
		case (difficulty)
			0001: begin  // Level 1: 2 seconds (count up to 100_000_000 - 1) 
				light_between <= 28'd99_999_999;
				light_on <= 28'd99_999_999;
			end
			0010: begin  // Level 2: 1 second
				light_between <= 28'd49_999_999;
				light_on <= 28'd49_999_999;
			end
			0100: begin  // Level 3: 0.50 seconds (count up to 25_000_000 - 1), 1 second countdown
				light_between <= 28'd24_999_999;
				light_on <= 28'd49_999_999;
			end
			1000: begin  // Level 4: 0.25 seconds (count up to 12_500_000 - 1), 0.50 second countdown
				light_between <= 28'd12_499_999;
				light_on <= 28'd24_999_999;
			end
			default: begin  // Same as Level 2: 1 second
				light_between <= 28'd49_999_999;
				light_on <= 28'd49_999_999;
			end
		endcase
	end

	always @(*)
	begin: Game mode
		case (gamemode)
			0001: begin  // Normal
				
			end
			0010: begin  // Timed
				
			end
			0100: begin  // Deathmatch (1 miss = you lose)
				
			end
			1000: begin  // Level continuity (start from 0 go to 4)
				
			end
			default: begin  // Same as normal
				
			end
		endcase
	end

	always @(*)
	begin: Game points
		case(SW[5])
			0: total_points <= normal_points;
			1: total_points <= extended_points;
			default: total_points <= normal_points;
		endcase
	end

	// ------------------------------------------------------------------------------------------------

	// Light controller
	light_controller LC(.CLOCK_50(CLOCK_50),
						.lights(LEDR));

	// Keypad controller
	keypad_controller KC(.column(key_matrix_column),
						 .clk(CLOCK_50),
						 .reset);

endmodule
