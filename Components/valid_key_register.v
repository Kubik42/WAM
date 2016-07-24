// Valid key register

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module valkeyreg(
    input clk,
    input reset,
    output reg valid_key
    );

    always @(posedge clk or negedge reset) begin
        if (~reset)
            valid_key <= 1'b0;
        else
            valid_key <= 1'b1;
    end
endmodule
