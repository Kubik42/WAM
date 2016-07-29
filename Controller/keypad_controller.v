// Design by Altium, with the addition of a few personal tweaks and features
// http://techdocs.altium.com/display/FPGA/KEYPADA_W+-+Wishbone+Keypad+Controller

`timescale 1ns / 1ns // `timescale time_unit/time_precision

`include "../Components/debouncer.v"
`include "../Components/encoder.v"
`include "../Components/column_decoder.v"
`include "../Components/key_register.v"
`include "../Components/valid_key_register.v"

module keypad_controller(
    input [2:0] row,
    input clk,
    input clear,
    output valid_key,
    output [2:0] column,
    output [3:0] key
    );

    // Clock dividers ----------------------------------------------------------

    wire clk_1MHz, clk_183Hz, clk_31Hz;  // Scan rate is approx six times slower than the debounce clock
    wire [27:0] counter_1MHz;
    wire [27:0] counter_183Hz;
    wire [27:0] counter_31Hz;
    // THESE ARE THE REAL TIMES, UNCOMMENT THEM WHEN NOT TESTING
    // localparam counter_max_1MHz  = 28'd49,     // Relative to 50Mhz
    //            counter_max_183Hz = 28'd5464,   // Relative to 1MHz
    //            counter_max_31Hz  = 28'd32257;  // Relative to 1MHz

    // JUST FOR TESTING, COMMENT OUT WHEN NOT TESTING
    localparam counter_max_1MHz  = 28'd5,
               counter_max_183Hz = 28'd50,
               counter_max_31Hz  = 28'd270;

    clock_divider CD_1MHz(.counter_max(counter_max_1MHz),
                          .clk(clk),
                          .enable(1'b1),
                          .reset(clear),
                          .counter(counter_1MHz));

    assign clk_1MHz = (counter_1MHz == 28'd0) ? 1 : 0;

    clock_divider CD_183Hz(.counter_max(counter_max_183Hz),
                           .clk(clk_1MHz),
                           .enable(1'b1),
                           .reset(clear),
                           .counter(counter_183Hz));

    assign clk_183Hz = (counter_183Hz == 28'd0) ? 1 : 0; 

    clock_divider CD_31Hz(.counter_max(counter_max_31Hz),
                          .clk(clk_1MHz),
                          .enable(1'b1),
                          .reset(clear),
                          .counter(counter_31Hz));

    assign clk_31Hz = (counter_31Hz == 28'd0) ? 1 : 0; 

    // -------------------------------------------------------------------------
    
    wire [1:0] row_number;
    wire [2:0] column_key;

    wire [1:0] counter;   

    // 2-bit binary counter, resets at 11
    counter BIN_COUNTER(.clk(clk_31Hz),
                        .reset(clear),
                        .counter(counter));

    // 3-bit to 2-bit Encoder and 2-bit to 3-bit decoder
    encoder ENC(.row(~row),
                .key(row_number));

    column_decoder DEC(.in(counter),
                       .column(column_key));
                
    // Key debouncer
    debouncer DEB(.row(row),
                  .clk(clk_183Hz),
                  .key_down(key_down));

    // Key register
    keyreg KEYREG(.pressed({counter, row_number}),
                  .clk(key_down), 
                  .reset(clear),
                  .key(key));

    // Valid key register
    valkeyreg VALKEYREG(.clk(key_down),
                        .reset(clear),
                        .valid_key(valid_key));

    assign column = ~column_key;
endmodule

// 2 bit synchronous counter, resets at 11
module counter(
    input clk,
    input reset,
    output reg [1:0] counter
    );

    always @(posedge clk or negedge reset) begin
        if (~reset)
            counter <= 2'd0;
        else if (counter[1])
            counter <= 2'd0;
        else
            counter <= counter + 2'b1;
    end
endmodule
