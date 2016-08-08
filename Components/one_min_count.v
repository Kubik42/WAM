// 6 bit counter
// Counts down from 60 to 0 (111100 to 0000000)

`timescale 1ns / 1ns // `timescale time_unit/time_precision
//`include "clock_divider.v"

module one_min_count(
    input clk,						// CLOCK_50
    input reset,
    input enable,
    output reg [5:0] counter
    );
    
    wire [27:0] counter_1Hz;
    wire clk_1Hz;
    wire clock_control;
    
    // 1Hz clock
    clock_divider CD_1Hz(.counter_max(28'd4),  // -=-=-=-=-=-=49_999_999 WHEN RUNNING -=-=-=-=-=-=
                         .clk(clk),
                         .enable(enable),
                         .reset(reset),
                         .counter(counter_1Hz));

    assign clk_1Hz = (counter_1Hz == 28'd0) ? 1 : 0;
			
    always @(posedge clk_1Hz, negedge reset)
	begin 
		if (!reset)
			counter <= 6'd60;
		else if (enable) begin
			if (counter != 6'd0)
				counter <= counter - 1'b1;
		end
	end
endmodule 
