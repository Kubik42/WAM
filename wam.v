`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "Controller/light_controller.v"
`include "Controller/keypad_controller.v"
`include "Components/one_min_decoder.v"
`include "Components/two_digit_decoder.v"

// KEY[0] - reset
// SW[3:0] - difficulty
// SW[9:6] - game mode
// SW[5]   - total game points

module wam(
    input [0:0] KEY,
    input [9:0] SW,
    input CLOCK_50,
    input [2:0] key_matrix_row,
    output reg [8:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3
    );

    assign play = KEY[0]; // all modules resets when 0
    reg load_seed, clear_memory;

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
                next_state = ? GAME_OVER : PLAY;
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
            end
            PLAY: begin
                load_seed = 1'b0;
                clear_memory = 1'b1;
                start_game = 1'b1;
            end
            GAME_OVER: begin
                load_seed = 1'b0;
                clear_memory = 1'b0;
                start_game = 1'b0;
            end
            RESTART: begin
                load_seed = 1'b0;
                clear_memory = 1'b0;
                start_game = 1'b0;
            end
        endcase
    end

    always @(posedge CLOCK_50 or negedge play)
    begin: game
        if (!play) begin
            current_state <= RESTART;
        end
        else begin
            current_state <= next_state;
        end
    end

    // Basic game settings -----------------------------------------------------

    // Switches
    wire [3:0] difficulty;
    assign difficulty = SW[3:0]

    wire [3:0] gamemode;
    assign gamemode = SW[9:6];

    // Points
    localparam normal_max_hits   = 6'd25,  // 25 light flicks
               extended_max_hits = 6'd50;  // 50 light flicks
    reg [5:0] total_points;                // number of hits (display on HEX3, HEX2)
    reg [6:0] max_hits;                    // maximum number of possible hits (display on HEX1, HEX0 when in game mode 0001 & 0100)

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
    wire [1:0] total_lives;
    wire [1:0] lives_left;
    
    always @(*)
    begin: game_mode
        case (gamemode)
            0001: begin  // Normal
                two_digit_decoder mode0hits(.b(max_hits), .reset(play), .hex0(HEX0), .hex1(HEX1));
                two_digit_decoder mode0points(.b(total_points), .reset(play), .hex0(HEX2), .hex1(HEX3));
            end
            0010: begin  // Timed
                one_min_count countdown(.clk(CLOCK_50), .reset(play), .start_game(start_game), .counter(time_left));
                two_digit_decoder mode1time(.b(time_left), .reset(play), .hex0(HEX0), .hex1(HEX1));
                two_digit_decoder mode1points(.b(total_points), .reset(play), .hex0(HEX2), .hex1(HEX3));
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
    begin: Maximum number of hits               
        case(SW[5])
            0: max_hits <= normal_max_hits;
            1: max_hits <= extended_max_hits;
            default: max_hits <= normal_max_hits;
        endcase
    end

    // -------------------------------------------------------------------------
    
    wire [3:0] light_pos, pressed;
    
    // Light controller
    light_controller LC(.time_on(time_on),
                        .time_between(time_between),
                        .load_seed(load_seed),
                        .start(start_game)
                        .clk(CLOCK_50),
                        .reset(play),
                        .lights(LEDR),
                        .light_pos(light_pos));

    // Keypad controller
    keypad_controller KC(.row(key_matrix_row),
                         .clk(CLOCK_50),
                         .clear(play),
                         .valid_key(pressed),
                         .column(),
                         .key(button_pressed));
    
    always @(*)
    begin: Record hits
        if (light_pos == button_pressed)
            total_points <= total_points + 1'b1;
    end
endmodule
