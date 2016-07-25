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
    output [8:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
    );

    assign play = ~KEY[0];

    wire [8:0] lights;
    assign LEDR = lights;

    wire [2:0] ready_counter;
    reg countdown, load_seed, start_game, clear_memory;

    // Points
    localparam normal_max_hits   = 6'd25,  // 25 light flicks
               extended_max_hits = 6'd50;  // 50 light flicks

    reg [5:0] total_points;   // points gotten by the player (displays on HEX3, HEX2)
    reg [5:0] max_hits;       // maximum number of possible hits (display on HEX1, HEX0 when in game mode 0001 & 0100)
    wire [5:0] light_counter;  // number of lights flicked

    // For other game modes
    // wire [5:0] time_left;
    // reg [1:0] total_lives;
    // reg [1:0] lives_left;

    // States ------------------------------------------------------------------

    reg [2:0] current_state, next_state;

    // States
    localparam SETUP     = 3'd0,
               WAIT      = 3'd1,
               PLAY      = 3'd2,
               GAME_OVER = 3'd3,
               RESTART   = 3'd4;

    always @(*)
    begin: state_table
        case(current_state)
            SETUP: next_state = play ? RESTART : SETUP;
            WAIT: next_state = (ready_counter == 3'd0) ? PLAY : WAIT;
            PLAY: begin
                next_state = play ? RESTART : PLAY;
                // The game is over when the required number of lights have been flicked
                next_state = (light_counter == max_hits) ? GAME_OVER : PLAY;
            end
            GAME_OVER: next_state = play ? RESTART : GAME_OVER;        
            RESTART: next_state = WAIT;
        endcase
    end

    always @(*)
    begin: game_setup
        // By default
        countdown = 1'b0;
        load_seed = 1'b0;
        clear_memory = 1'b0;  // Note: negedge trigger
        start_game = 1'b0;

        case(current_state)
            SETUP: begin
                countdown = 1'b0;           
                load_seed = 1'b1;  // Seed is loaded only once
                clear_memory = 1'b1;
                start_game = 1'b0;
            end
            WAIT: begin
                countdown = 1'b1;
                load_seed = 1'b0;
                clear_memory = 1'b1;
                start_game = 1'b0;
            end
            PLAY: begin
                countdown = 1'b0;
                load_seed = 1'b0;
                clear_memory = 1'b1;
                start_game = 1'b1;
            end
            GAME_OVER: begin
                countdown = 1'b0;
                load_seed = 1'b0;
                clear_memory = 1'b1;
                start_game = 1'b0;
            end
            RESTART: begin
                countdown = 1'b0;
                load_seed = 1'b0;
                clear_memory = 1'b0;
                start_game = 1'b0;
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

    // Enable signals
    reg use_points, use_timer, use_lives;

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

    always @(*)
    begin: mode
        // By default
        use_points = 1'b0;
        use_timer = 1'b0;
        use_lives  = 1'b0;

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

    // Ready countdown ---------------------------------------------------------

    wire [27:0] countdown_counter;
    wire start_countdown;

    // Countdown every 1 second
    clock_divider CD_1Hz(.counter_max(28'd49_999_999),
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
                      .hex(HEX5));

    // -------------------------------------------------------------------------

    // always @(*)
    // begin: game_mode
    //     // By default
    //     total_lives <= 0; 
    //     lives_left <= 0;

    //     case (gamemode)
    //         0001: begin  // Normal
    //             two_digit_decoder mode0hits(.b(max_hits), .reset(clear_memory), .hex0(HEX0), .hex1(HEX1));
    //             two_digit_decoder mode0points(.b(total_points), .reset(clear_memory), .hex0(HEX2), .hex1(HEX3));
    //         end
    //         0010: begin  // Timed
    //             one_min_count countdown(.clk(CLOCK_50), .reset(clear_memory), .start_game(start_game), .counter(time_left));
    //             two_digit_decoder mode1time(.b(time_left), .reset(clear_memory), .hex0(HEX0), .hex1(HEX1));
    //             two_digit_decoder mode1points(.b(total_points), .reset(clear_memory), .hex0(HEX2), .hex1(HEX3));
    //         end
    //         0100: begin  // Deathmatch (1 miss = you lose)
    //             total_lives <= 2'b1;
    //             lives_left <= 2'b1;
    //             bdd mode2lives(.binary({2'd0, lives_left}), .reset(clear_memory), .hex(HEX0));
    //             two_digit_decoder mode2points(.b(total_points), .reset(clear_memory), .hex0(HEX2), .hex1(HEX3));
    //         end
    //         1000: begin  // Level continuity (start from 0 go to 4)
    //             two_digit_decoder mode3hits(.b(max_hits), .reset(clear_memory), .hex0(HEX0), .hex1(HEX1));
    //             two_digit_decoder mode3points(.b(total_points), .reset(clear_memory), .hex0(HEX2), .hex1(HEX3));
    //         end
    //         default: begin  // Same as normal
    //         end
    //     endcase
    // end

    // -------------------------------------------------------------------------
    
    wire has_input;
    wire [3:0] light_pos, key_pressed;
    
    // Light controller
    light_controller LC(.time_on(time_on),
                        .time_between(time_between),
                        .load_seed(load_seed),
                        .start(start_game),
                        .clk(CLOCK_50),
                        .reset(clear_memory),
                        .lights(lights),
                        .light_pos(light_pos),
                        .light_counter(light_counter));

    // Keypad controller
    keypad_controller KC(.row(key_matrix_row),
                         .clk(CLOCK_50),
                         .clear(clear_memory),
                         .valid_key(has_input),
                         .column(column),
                         .key(key_pressed));
   
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
            counter <= 3'd5;
        else if (counter == 3'd0)
            counter <= 3'd5;
        else if (enable) begin
            counter <= counter - 3'b1;
        end
    end
endmodule
