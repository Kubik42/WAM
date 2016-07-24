`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "Controller/light_controller.v"
`include "Controller/keypad_controller.v"
`include "Components/one_min_decoder.v"
`include "Components/two_digit_decoder.v"
`include "Components/bin_dec_decoder.v"
`include "Components/light_decoder.v"

// KEY[0] - reset
// SW[3:0] - difficulty
// SW[9:6] - game mode
// SW[5]   - total game points

// Expansion header for signals input and output
// p.33 ftp://ftp.altera.com/up/pub/Altera_Material/Boards/DE1/DE1_User_Manual.pdf
// GPIO_0[11] - 5V DC
// GPIO_0[29] - 3.3V DC
// GPIO_0[12] - GND
// GPIO_0[2:0] - input 
// GPIO_0[5:3] - output


module wam(
    input [0:0] KEY,
    input [9:0] SW,
    input CLOCK_50,
    input [2:0] key_matrix_row,
    output [2:0] column,
    output reg [8:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3
    );

    assign play = ~KEY[0];
    reg load_seed, clear_memory, gameover;

    // States ------------------------------------------------------------------

    wire [1:0] current_state, next_state;

    // States
    localparam SETUP     = 2'd0,
               PLAY      = 2'd1,
               GAME_OVER = 2'd2,
               RESTART   = 2'd3;

    always @(*)
    begin: state_table
        case(current_state)
            SETUP: next_state = play ? PLAY : SETUP;
            PLAY: begin
                next_state = play ? RESTART : PLAY;  
                next_state = gameover ? GAME_OVER : PLAY;
            end
            GAME_OVER: next_state = play ? RESTART : GAME_OVER;          
            RESTART: next_state = PLAY;
        endcase
    end

    always @(*)
    begin: game_setup
        // By default
        load_seed = 1'b0;
        clear_memory = 1'b0;  // Note: negedge trigger
        start_game = 1'b0;

        case(current_state)
            SETUP: begin
                load_seed = 1'b1;  // Seed is loaded only once
                clear_memory = 1'b1;
                start_game = 1'b0;
                gameover = 1'b0;
            end
            PLAY: begin
                load_seed = 1'b0;
                clear_memory = 1'b1;
                start_game = 1'b1;
                gameover = 1'b0;
            end
            GAME_OVER: begin
                load_seed = 1'b0;
                clear_memory = 1'b1;
                start_game = 1'b0;
                gameover = 1'b1;
            end
            RESTART: begin
                load_seed = 1'b0;
                clear_memory = 1'b0;
                start_game = 1'b0;
                gameover = 1'b0;
            end
        endcase
        // Game over
    	if ((max_hits == light_flicks) || ((total_lives != 0) && (lives_left == 0)) // no more hits or no more lives
    		gameover <= 1'b1; 
    end

    always @(posedge CLOCK_50 or negedge play)
    begin: game
        if (play) begin
            current_state <= RESTART;
        end
        else begin
            current_state <= next_state;
        end
    end

    // Basic game settings -----------------------------------------------------

    // Switches
    wire [3:0] difficulty;
    assign difficulty = SW[3:0];

    wire [3:0] gamemode;
    assign gamemode = SW[9:6];

    // Points
    localparam normal_max_hits   = 6'd25,  // 25 light flicks
               extended_max_hits = 6'd50;  // 50 light flicks
    reg [5:0] total_points;                // number of hits (display on HEX3, HEX2)
    reg [5:0] max_hits;                    // maximum number of possible hits (display on HEX1, HEX0 when in game mode 0001 & 0100)
    reg [5:0] light_flicks;				// number of lights flicked

    // Counters/timers
    reg [27:0] time_between;  // Time between subsequent light flicks
    reg [27:0] time_on;  // Time the light will stay on for

    always @(*) 
    begin : Difficulty
        case (difficulty)
            0001: begin  // Level 1: 2 seconds (count up to 100_000_000 - 1) 
                time_between <= 28'd99_999_999;
                time_on <= 28'd99_999_999;
            end
            0010: begin  // Level 2: 1 second
                time_between <= 28'd49_999_999;
                time_on <= 28'd49_999_999;
            end
            0100: begin  // Level 3: 0.50 seconds (count up to 25_000_000 - 1), 1 second countdown
                time_between <= 28'd24_999_999;
                time_on <= 28'd49_999_999;
            end
            1000: begin  // Level 4: 0.25 seconds (count up to 12_500_000 - 1), 0.50 second countdown
                time_between <= 28'd12_499_999;
                time_on <= 28'd24_999_999;
            end
            default: begin  // Same as Level 2: 1 second
                time_between <= 28'd49_999_999;
                time_on <= 28'd49_999_999;
            end
        endcase
    end
    
    wire [5:0] time_left;
    reg [1:0] total_lives;
    reg [1:0] lives_left;
    
    always @(*)
    begin: game_mode
    	// By default
    	total_lives <= 0; 
    	lives_left <= 0; 
        case (gamemode)
            0001: begin  // Normal
                two_digit_decoder mode0hits(.b(max_hits), .reset(clear_memory), .hex0(HEX0), .hex1(HEX1));
                two_digit_decoder mode0points(.b(total_points), .reset(clear_memory), .hex0(HEX2), .hex1(HEX3));
            end
            0010: begin  // Timed
                one_min_count countdown(.clk(CLOCK_50), .reset(clear_memory), .start_game(start_game), .counter(time_left));
                two_digit_decoder mode1time(.b(time_left), .reset(clear_memory), .hex0(HEX0), .hex1(HEX1));
                two_digit_decoder mode1points(.b(total_points), .reset(clear_memory), .hex0(HEX2), .hex1(HEX3));
            end
            0100: begin  // Deathmatch (1 miss = you lose)
                total_lives <= 2'b1;
                lives_left <= 2'b1;
                bdd mode2lives(.binary({2'd0, lives_left}), .reset(clear_memory), .hex(HEX0));
                two_digit_decoder mode2points(.b(total_points), .reset(clear_memory), .hex0(HEX2), .hex1(HEX3));
            end
            1000: begin  // Level continuity (start from 0 go to 4)
                two_digit_decoder mode3hits(.b(max_hits), .reset(clear_memory), .hex0(HEX0), .hex1(HEX1));
                two_digit_decoder mode3points(.b(total_points), .reset(clear_memory), .hex0(HEX2), .hex1(HEX3));
            end
            default: begin  // Same as normal
                
            end
        endcase
    end

    always @(*)
    begin: Maximum number of hits               
        case(SW[5])
            0: max_hits <= normal_max_hits;
            1: max_hits <= extended_max_hits;
            default: max_hits <= normal_max_hits;
        endcase
    end

    // -------------------------------------------------------------------------
    
    wire has_input, light_off;
    wire [3:0] light_pos, light_coord, key_pressed;
    
    // Light controller
    light_controller LC(.time_on(time_on),
                        .time_between(time_between),
                        .load_seed(load_seed),
                        .start(start_game)
                        .clk(CLOCK_50),
                        .reset(clear_memory),
                        .lights(LEDR),
                        .light_pos(light_pos),
                        .btwn_light(light_off)); // For recording number of light flicks

    // Keypad controller
    keypad_controller KC(.row(key_matrix_row),
                         .clk(CLOCK_50),
                         .clear(clear_memory),
                         .valid_key(has_input),
                         .column(column),
                         .key(key_pressed));
    
    // Light decoder
    liglht_decoder LD(.in(light_pos), 
    					.coordinates(light_coord));
    
    always @(*)
    begin: Record_hits
        if (has_input) begin
            if (light_coord == key_pressed)
                total_points <= total_points + 1'b1;
        end
        // Clear memory here
    end
    
    always @(posedge light_off)
    begin: Record light flick
    		light_flicks <= light_flicks + 1;
    end

endmodule
