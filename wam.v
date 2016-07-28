`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "Controller/light_controller.v"
`include "Controller/keypad_controller.v"
`include "Components/clock_divider.v"
`include "Components/one_min_count.v"
`include "Components/two_digit_decoder.v"
`include "Components/bin_dec_decoder.v"
`include "Components/light_decoder.v"

// KEY[0] - reset
// SW[3:0] - difficulty
// SW[9:6] - game mode
// SW[5]   - total game points

// Displays:
//   HEX0: max hits
//   HEX1: max hits
//   HEX2: score (player hits)
//   HEX3: score (player hits)
//   HEX4: timer
//   HEX5: ready timer / timer

// Expansion header for signals input and output
// GPIO_0[11] - GND
// GPIO_0[2:0] - column output
// GPIO_1[8:0] - buttons input
// GPIO_1[16:14] - row input

module wam(
    input [0:0] KEY,
    input [9:0] SW,
    input CLOCK_50,
    //input [2:0] key_matrix_row,
	input [16:0] GPIO_1,
    output [2:0] column,
	output [16:0] GPIO_0,
    output [8:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
    );
	
	//wire [2:0] key_matrix_row;
	//assign key_matrix_row = GPIO_1[3:1];
	
	//assign GPIO_0[3:1] = column; 
	
    assign play = ~KEY[0];

    wire [8:0] lights;
    assign LEDR = lights;

    // Points
    localparam normal_max_hits   = 6'd25,  // 25 light flicks
               extended_max_hits = 6'd50;  // 50 light flicks

    reg [5:0] total_points;   // points gotten by the player (displays on HEX3, HEX2)
    reg [5:0] max_hits;       // maximum number of possible hits (display on HEX1, HEX0 when in game mode 0001 & 0100)
    wire [5:0] light_counter;  // number of lights flicked

    // For other game modes
    wire [5:0] time_left;
    // reg [1:0] total_lives;
    // reg [1:0] lives_left;

    // States ------------------------------------------------------------------

    reg [2:0] current_state, next_state;

    wire [2:0] ready_counter;

    // Enable signals
    reg countdown, load_seed, flick_lights, clear_memory;
    reg use_points, use_timer, use_lives;

    // States
    localparam SETUP     = 3'd0,
               WAIT      = 3'd1,
               PLAY      = 3'd2,
               GAME_OVER = 3'd3,
               RESTART   = 3'd4;

    // Default initializations
    initial begin
        countdown = 1'b0;
        load_seed = 1'b0;
        clear_memory = 1'b0;  // Note: negedge trigger
        flick_lights = 1'b0;

        use_points = 1'b0;
        use_timer = 1'b0;
        use_lives = 1'b0;
        
		total_points <= 6'd0;
        current_state <= SETUP;
    end

    always @(*)
    begin: state_table
        case (current_state)
            SETUP: next_state = play ? RESTART : SETUP;
            WAIT: next_state = (ready_counter == 3'd0) ? PLAY : WAIT;
            PLAY: begin
				if (play)
					next_state = RESTART;
				else if (light_counter == max_hits)
					next_state = GAME_OVER;
				else
					next_state = PLAY;
					
                //next_state = play ? RESTART : PLAY;
                // The game is over when the required number of lights have been flicked
                //next_state = (light_counter == max_hits) ? GAME_OVER : PLAY;
            end
            GAME_OVER: next_state = play ? RESTART : GAME_OVER;        
            RESTART: next_state = WAIT;
        endcase
    end

    always @(*)
    begin: game_setup
        case (current_state)
            SETUP: begin
                countdown = 1'b0;           
                load_seed = 1'b1;  // Seed is loaded only once
                clear_memory = 1'b1;
                flick_lights = 1'b0;
            end
            WAIT: begin
                countdown = 1'b1;
                load_seed = 1'b0;
                clear_memory = 1'b1;
                flick_lights = 1'b0;
            end
            PLAY: begin
                countdown = 1'b0;
                load_seed = 1'b0;
                clear_memory = 1'b1;
                flick_lights = 1'b1;
            end
            GAME_OVER: begin
                countdown = 1'b0;
                load_seed = 1'b0;
                clear_memory = 1'b1;
                flick_lights = 1'b0;
            end
            RESTART: begin
                countdown = 1'b0;
                load_seed = 1'b0;
                clear_memory = 1'b0;
                flick_lights = 1'b0;
            end
        endcase
    end

    always @(posedge CLOCK_50)
    begin: game
        current_state <= next_state;     
    end

    // Basic game settings -----------------------------------------------------

    wire [3:0] difficulty;
    assign difficulty = SW[3:0];

    wire [3:0] game_mode;
    assign game_mode = SW[9:6];

    // Counters/timers
    reg [27:0] time_between;  // Time between subsequent light flicks
    reg [27:0] time_on;  // Time the light will stay on for

    always @(*) 
    begin : Difficulty
        case (difficulty)
            0001: begin  // Level 1: 2 seconds (count up to 100_000_000 - 1) 
                time_between <= 28'd99;
                time_on <= 28'd99;
            end
            0010: begin  // Level 2: 1 second
                time_between <= 28'd49_999_999;
                time_on <= 28'd49_999_999;
            end
            0100: begin  // Level 3: 0.50 second (count up to 25_000_000 - 1), 0.5 second countdown
                time_between <= 28'd24_999_999;
                time_on <= 28'd24_999_999;
            end
            1000: begin  // Level 4: 0.25 second (count up to 12_500_000 - 1), 0.50 second countdown
                time_between <= 28'd12_499_999;
                time_on <= 28'd12_499_999;
            end
            default: begin  // Same as Level 2: 1 second
                time_between <= 28'd49_999_999;
                time_on <= 28'd49_999_999;
            end
        endcase
    end

    always @(*)
    begin: mode
        case (game_mode)
            4'b1000: begin  // Normal mode
                use_points = 1'b1;
                use_timer = 1'b0;
                use_lives = 1'b0;
            end
            4'b0100: begin  // Timed mode
                use_points = 1'b0;
                use_timer = 1'b1;
                use_lives = 1'b0;
            end
            4'b0010: begin  // Lives mode
                use_points = 1'b0;
                use_timer = 1'b0;
                use_lives = 1'b1;
            end
            4'b0001: begin  // Continuity --- MAY BE TOO HARD TO IMPLEMENT???, same as normal rn
                use_points = 1'b1;
                use_timer = 1'b0;
                use_lives = 1'b0;
            end
            default: begin  // Sme as normal
                use_points = 1'b1;
                use_timer = 1'b0;
                use_lives = 1'b0;
            end
        endcase
    end

    always @(*)
    begin: hits
        case(SW[5])
            0: max_hits <= normal_max_hits;
            1: max_hits <= extended_max_hits;
            default: max_hits <= normal_max_hits;
        endcase
    end

    // Dispalying score
    two_digit_decoder TOTAL(.b(max_hits),
                            .enable(use_points),
                            .reset(clear_memory),
                            .hex0(HEX0),
                            .hex1(HEX1));

    two_digit_decoder PLAYER_SCORE(.b(total_points),
                                   .enable(~countdown),
                                   .reset(clear_memory),
                                   .hex0(HEX2),
                                   .hex1(HEX3));
	// Timed mode
	wire [6:0] timer, ready;
	reg [6:0] hex5;
     one_min_count ONE_MIN(.clk(CLOCK_50), 
     				.reset(clear_memory), 
     				.start_game(flick_lights), 
     				.counter(time_left));
     
     two_digit_decoder TIMER(.b(time_left),
                            .enable(flick_lights),
                            .reset(clear_memory),
                            .hex0(HEX4),
                            .hex1(timer));
                            
    always @(*) begin // HEX5 display switching
		if (current_state == PLAY)
			hex5 <= timer;
		else
			hex5 <= ready;
	end
	
	//always @(*) begin // HEX5 display switching (without 5s countdown for timed mode)
	//	if (use_timer)
	//		hex5 <= timer;
	//	else
	//		hex5 <= ready;
	//end
	
	assign HEX5 = hex5;

    // Ready countdown ---------------------------------------------------------

    wire [27:0] countdown_counter;
    wire start_countdown;

    // Countdown every 1 second
    clock_divider CD_1Hz(.counter_max(28'd4),  // should be 49_999_999
                         .clk(CLOCK_50),
                         .enable(countdown),
                         .reset(clear_memory),
                         .counter(countdown_counter));

    assign start_countdown = (countdown_counter == 28'd0) ? 1 : 0;

    countdown_timer COUNTDOWN(.clk(CLOCK_50),
                              .enable(start_countdown),
                              .reset(clear_memory),
                              .counter(ready_counter));

    bdd COUNTDOWN_DIS(.binary({1'b0, ready_counter}),
                      .enable(start_countdown),
                      .reset(clear_memory),
                      .hex(ready));
    
    wire has_input;
    wire [3:0] light_pos, key_pressed;
    
    // Light controller
    light_controller LC(.time_on(time_on),
                        .time_between(time_between),
                        .load_seed(load_seed),
                        .start(flick_lights),
                        .clk(CLOCK_50),
                        .reset(clear_memory),
                        .lights(lights),
                        .light_pos(light_pos),
                        .light_counter(light_counter));

    // Keypad controller
	wire temp;
    keypad_controller KC(.row(key_matrix_row),
                         .clk(CLOCK_50),
                         .clear(clear_memory),
                         .valid_key(has_input),
                         .column(column),
                         .key(key_pressed),
						.key_down(temp));
	
	//assign LEDR[2:0] = GPIO_0[3:1];
	//assign LEDR[6:4] = GPIO_1[3:1];
	//assign LEDR[8:6] = column;
	//assign LEDR[9] = temp;
						 
	//always @(*) begin
	//	case (key_pressed)
	//		4'b0000: LEDR[8:0] <= 9'b000000001;
	//		4'b0001: LEDR[8:0] <= 9'b000000010;
	//		4'b0010: LEDR[8:0] <= 9'b000000100;
	//		4'b0011: LEDR[8:0] <= 9'b000001000;
	//		4'b0100: LEDR[8:0] <= 9'b000010000;
	//		4'b0101: LEDR[8:0] <= 9'b000100000;
	//		4'b0110: LEDR[8:0] <= 9'b001000000;
	//		4'b0111: LEDR[8:0] <= 9'b010000000;
	//		4'b1000: LEDR[8:0] <= 9'b100000000;
	//	endcase
	//	LEDR[9] <= temp;
	//end
   
    always @(*)
    begin: record_hits
        if (has_input) begin
            if (light_pos == key_pressed)
                total_points <= total_points + 1'b1;
        end
    end
endmodule

// Ready countdown timer
module countdown_timer(
    input clk,
    input enable,
    input reset,
    output reg [2:0] counter
    );

    always @(posedge clk or negedge reset) begin
        if (~reset)
            counter <= 3'd6;
        else if (counter == 3'd0)
            counter <= 3'd6;
        else if (enable) begin
            counter <= counter - 3'b1;
        end
    end
endmodule
