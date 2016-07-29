// 2-bit to 3-bit decoder

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module column_decoder(
    input [1:0] in,
    output reg [2:0] column
    );

    always @(*) begin
        case (in)
            2'd0: column <= 3'b100;  // Col 1
            2'd1: column <= 3'b010;  // Col 2
            2'd2: column <= 3'b001;  // Col 3
            default: column <= 3'b000;
        endcase     
    end
endmodule
