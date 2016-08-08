`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "Controller/light_controller.v"
`include "Controller/keypad_controller.v"
`include "Components/clock_divider.v"
`include "Components/one_min_count.v"
`include "Components/two_digit_decoder.v"
`include "Components/bin_dec_decoder.v"
`include "Components/light_decoder.v"

// Options:
//   KEY[0]  - reset
//   KEY[1]  - life counter
//   SW[3:0] - difficulty
//   SW[9:7] - game mode
//   SW[5]   - total game points

// Displays:
//   HEX0: max hits
//   HEX1: max hits
//   HEX2: score (player hits)
//   HEX3: score (player hits)
//   HEX4: game mode timer
//   HEX5: ready timer / game mode timer

// Expansion header for signals input and output:
//   GPIO_0[11]    - GND
//   GPIO_0[2:0]   - column output
//   GPIO_0[20:12] - lights output
//   GPIO_1[2:0]   - row input

module wam(
    input [1:0] KEY,
    input [9:0] SW,
    input CLOCK_50,
    //input [2:0] key_matrix_row,  // -=-=-=-=-=COMMENT OUT WHEN RUNNING-=-=-=-=-=
    input [20:0] GPIO_1,
    output [2:0] column,
    output [20:0] GPIO_0,
    output [8:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
    );
    
    // --=-=-=-=-=-UNCOMMENT WHEN RUNNING-=-=-=-=-=-==-=
    wire [2:0] key_matrix_row;
    assign key_matrix_row = GPIO_1[2:0];
    
    assign GPIO_0[2:0] = column; 
    
    assign play = ~KEY[0];
    assign extra_life = ~KEY[1];

    wire [8:0] lights;
    assign GPIO_0[20:12] = ~lights;
    //assign LEDR = lights;

    // Points
    localparam normal_max_hits   = 6'd25,  // 25 light flicks
               extended_max_hits = 6'd50;  // 50 light flicks

    reg [5:0] total_points;    // player hits/points (displays on HEX3, HEX2)
    reg [5:0] max_hits;        // max possible hits/points (display on HEX1, HEX0 when in game mode 0001 & 0100)
    wire [5:0] light_counter;  // number of lights flicked

    // For other game modes
    wire [5:0] time_left;
    reg [3:0] total_lives;
    reg [3:0] lives_left;


    // State machine -----------------------------------------------------------

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

        total_lives <= 4'd0;
        lives_left <= 4'd0;
        
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
                else if (use_points && light_counter == max_hits)
                    next_state = GAME_OVER;
                else if (use_timer && time_left == 28'd0)
                    next_state = GAME_OVER;
                else if (use_lives && lives_left == 4'd0)
                    next_state = GAME_OVER;
                else
                    next_state = PLAY;
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
    assign game_mode = SW[9:7];

    // Counters/timers
    reg [27:0] time_between;  // Time between subsequent light flicks
    reg [27:0] time_on;  // Time the light will stay on for

    always @(*) 
    begin: difficulty_level
        case (difficulty)
            4'b0001: begin  // Level 1: 2 seconds
                time_between <= 28'd99_999_999;
                time_on <= 28'd99_999_999;
            end
            4'b0010: begin  // Level 2: 1 second
                time_between <= 28'd49_999_999;
                time_on <= 28'd49_999_999;
            end
            4'b0100: begin  // Level 3: 0.50 second, 0.50 second countdown
                time_between <= 28'd24_999_999;
                time_on <= 28'd24_999_999;
            end
            4'b1000: begin  // Level 4: 0.25 second, 0.25 second countdown
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
            3'b100: begin  // Normal mode
                use_points = 1'b1;
                use_timer = 1'b0;
                use_lives = 1'b0;
            end
            3'b010: begin  // Timed mode
                use_points = 1'b0;
                use_timer = 1'b1;
                use_lives = 1'b0;
            end
            3'b001: begin  // Lives mode 
                use_points = 1'b0;
                use_timer = 1'b0;
                use_lives = 1'b1;
            end
            default: begin  // Same as normal
                use_points = 1'b1;
                use_timer = 1'b0;
                use_lives = 1'b0;
            end
        endcase
    end

    always @(posedge extra_life)
    begin: life_count
        if (current_state == SETUP || current_state == GAME_OVER) begin
            if (total_lives == 4'd9)  // 9 lives maximum, 1 life minimum
                total_lives <= 4'd1;
            else
                total_lives <= total_lives + 4'd1;
        end
    end

    always @(*)
    begin: point_hits
        if (current_state == SETUP || current_state == GAME_OVER) begin
            case (SW[5])
                1'b0: max_hits <= normal_max_hits;
                1'b1: max_hits <= extended_max_hits;
                default: max_hits <= normal_max_hits;
            endcase
        end
    end


    // Score -------------------------------------------------------------------

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
    wire [6:0] countdown_display;

    // Countdown every 1 second
    clock_divider CD_1Hz(.counter_max(28'd49_999_999),  // -=-=-=-=-=-49_999_999 WHEN RUNNING -=-=-=-=-
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
                      .hex(countdown_display));


    // Timed mode timer --------------------------------------------------------

    wire [6:0] timer0, timer1;

    one_min_count ONE_MIN(.clk(CLOCK_50), 
                          .reset(clear_memory), 
                          .enable(use_timer & ~countdown), 
                          .counter(time_left));
     
    two_digit_decoder TIMER(.b(time_left),
                            .enable(use_timer & ~countdown),
                            .reset(clear_memory),
                            .hex0(timer0),
                            .hex1(timer1));


    // Lives mode display ------------------------------------------------------

    wire [6:0] total_lives_count, player_lives_count;

    bdd TOTAL_LIVES(.binary(total_lives),
                    .enable(use_lives & ~countdown),
                    .reset(clear_memory),
                    .hex(total_lives_count));

    bdd PLAYER_LIVES(.binary(lives_left),
                     .enable(use_lives & ~countdown),
                     .reset(clear_memory),
                     .hex(player_lives_count));


    // Display switching -------------------------------------------------------

    reg [6:0] hex5, hex4;
      
    always @(*)
    begin: timer_display_switch
        if (current_state == WAIT) begin
            if (countdown) begin
                hex4 <= 7'b1111111;
                hex5 <= countdown_display;               
            end
        end
        else begin
            if (use_timer) begin
                hex4 <= timer0;
                hex5 <= timer1;
            end            
            else if (use_lives) begin
                hex4 <= total_lives_count;
                hex5 <= player_lives_count;
            end
            else begin
                hex4 <= 7'b1111111;
                hex5 <= 7'b1111111;
            end
        end
    end

    assign HEX4 = hex4;
    assign HEX5 = hex5;


    // Controllers -------------------------------------------------------------
    
    wire has_input, key_down, light_change;
    wire [3:0] light_pos, key_pressed;
    
    light_controller LC(.time_on(time_on),
                        .time_between(time_between),
                        .load_seed(load_seed),
                        .start(flick_lights),
                        .clk(CLOCK_50),
                        .reset(clear_memory),
                        .lights(lights),
                        .light_pos(light_pos),
                        .light_counter(light_counter),
                        .light_change(light_change));

    keypad_controller KC(.row(key_matrix_row),
                         .clk(CLOCK_50),
                         .clear(clear_memory),
                         .valid_key(has_input),
                         .column(column),
                         .key(key_pressed),
                         .key_down(key_down));


    // For testing lights
    // always @(*)
    // begin
    //     LEDR[9] <= temp;
    //     case (key_pressed)
    //         4'b0000: LEDR[8:0] <= 9'b000000001;
    //         4'b0001: LEDR[8:0] <= 9'b000000010;
    //         4'b0010: LEDR[8:0] <= 9'b000000100;
    //         4'b0011: LEDR[8:0] <= 9'b000001000;
    //         4'b0100: LEDR[8:0] <= 9'b000010000;
    //         4'b0101: LEDR[8:0] <= 9'b000100000;
    //         4'b0110: LEDR[8:0] <= 9'b001000000;
    //         4'b0111: LEDR[8:0] <= 9'b010000000;
    //         4'b1000: LEDR[8:0] <= 9'b100000000;
    //     endcase
    //     LEDR[9] <= temp;
    // end
 

    // Hit recording -----------------------------------------------------------

    always @(*)
    begin: record_hits
        if (key_down) begin
            if (light_pos == key_pressed)
                total_points <= total_points + 1'b1;
        end
    end
    
    // Lives recording -----------------------------------------------------------
    
    always @(posedge light_change)
    begin: lost_life
        if (use_lives) begin
            if (current_state == RESTART)
                lives_left <= total_lives;
            else if (key_down && (light_pos != key_pressed))
                lives_left <= lives_left - 1'b1;
        end
    end
endmodule

// 6 second ready countdown timer
// NOTE: the display will start counting from 5 (doesn't show 6)
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
