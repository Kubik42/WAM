// Design by Altium, with the addition of a few personal tweaks and features
// http://techdocs.altium.com/display/FPGA/KEYPADA_W+-+Wishbone+Keypad+Controller

`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "../Components/debouncer.v"
`include "../Components/clock_divider.v"
`include "../Components/D_flip_flop.v"
`include "../Components/T_flip_flop.v"
`include "../Components/encoder.v"
`include "../Components/decoder.v"
`include "../Components/key_register.v"
`include "../Components/key_down_register.v"

module keypad_controller(
    input [2:0] row,
    input clk,
    input reset,
    output reg valid_key,
    output [2:0] column,
    output [3:0] key // Position of the button pressed (0-8)
    );

    // Clock dividers ----------------------------------------------------------

    wire clk_1MHz, clk_183Hz, clk_31Hz;  // Scan rate is approx six times slower than the debounce clock
    wire [5:0] counter_1Mhz;
    wire [12:0] counter_183Hz;
    wire [14:0] counter_31Hz;
    localparam [5:0]  counter_max_1MHz = 6'd49,       // Relative to 50Mhz
               [12:0] counter_max_183Hz = 13'd5464  // Relative to 1MHz
               [14:0] counter_max_31Hz = 15'd32257;  // Relative to 1MHz              

    clock_divider CD_1Hz(.counter_max(counter_max_1Hz),
                         .clk(clk),
                         .enable(1'b1),
                         .reset(reset),
                         .counter(counter_1MHz));

    assign clk_1MHz = (counter_1MHz == 6'd0) ? 1 : 0;

    clock_divider CD_183Hz(.counter_max(counter_max_183Hz),
                           .clk(clk_1Hz),
                           .enable(1'b1),
                           .reset(reset),
                           .counter(counter_183Hz));

    assign clk_183Hz = (counter_183Hz == 13'd0) ? 1 : 0; 

    clock_divider CD_31Hz(.counter_max(counter_max_31Hz),
                          .clk(clk_1Hz),
                          .enable(1'b1),
                          .reset(reset),
                          .counter(counter_31Hz));

    assign clk_31Hz = (counter_31Hz == 15'd0) ? 1 : 0; 

    // -------------------------------------------------------------------------

    // Key debouncer
    debouncer DEB(.row(row),
                .clk(clk_183Hz),
                .key_down(key_down));

    // Key register
    keyreg KEYREG(.pressed({row_key, column_key}),
                        .clk(key_down),
                        .reset(reset),
                        .key(key));

    // Valid key register
    valkeyreg VALKEYREG(.clk(key_down),
                        .reset(),
                        .valid_key(valid_key));

    // Counter
    wire [1:0] counter;  // 2-bit counter

    counter C(.clk(clk_31Hz),
              .counter(counter));


    // 3-bit to 2-bit Encoder and 2-bit to 3-bit decoder
    wire [1:0] row_key;
    wire [1:0] column_key;

    encoder ENC(.row(~row),
                .key(row_key));

    decoder DEC(.in(counter),
                .column(column_key));

    assign column = ~column_key;
    assign key = ((2'd3)*{2'b00, row_key} + {2'b00, column_key}); 
endmodule

// 2 bit synchronous counter, resets at 11
module counter(
    input clk,
    output reg [1:0] counter
    );

    tff F0(.data(1'b1),
           .clk(clk),
           .reset(~(counter[0] & counter[1])),
           .Q(counter[0]));

    tff F1(.data(1'b1 & counter[0]),
           .clk(clk),
           .reset((~(counter[0] & counter[1])),
           .Q(counter[1]));

    //assign counter = Q;
endmodule
