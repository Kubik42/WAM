module one_min_count(
    input clk,						// CLOCK_50
    input reset,
    input start_game,
    output [5:0] output_time
    );
    
    wire [27:0] counter_1Hz;
    wire [5:0] counter;
    wire clk_1Hz;
    wire clock_control;
    
    // 1Hz clock
    clock_divider CD_1Hz(.counter_max(28'd49_999),
                         .clk(clk),
                         .enable(clock_control),
                         .reset(reset),
                         .counter(counter_1Hz));

    assign clk_1Hz = (counter_1Hz == 28'd0) ? 1 : 0;
    assign clock_control = (start_game) ? 1 : 0;
    
    // T-flip-flops count down circuit
    tff F0(.data(1'b1),
           .clk(clk_1Hz),
           .reset(reset),
           .Q(counter[0]));

    tff F1(.data(1'b1),
           .clk(counter[0]),
           .reset(reset),
           .Q(counter[1]));
    
    tff F2(.data(1'b1),
           .clk(counter[1]),
           .reset(reset),
           .Q(counter[2]));
    
    tff F3(.data(1'b1),
           .clk(counter[2]),
           .reset(reset),
           .Q(counter[3]));
    
    tff F4(.data(1'b1),
           .clk(counter[3]),
           .reset(reset),
           .Q(counter[4]));
    
    tff F5(.data(1'b1),
           .clk(counter[4]),
           .reset(reset),
           .Q(counter[5]));
    
    assign output_time = counter;

endmodule 

