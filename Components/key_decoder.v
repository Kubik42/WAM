// Key decoder

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module key_decoder(
    input [3:0] key,
    output reg [3:0] key_number
    );

    always @(*)
    begin
        case (key)
            4'b0000: key_number <= 4'd0;
            4'b0100: key_number <= 4'd1;
            4'b1000: key_number <= 4'd2;
            4'b0001: key_number <= 4'd3;
            4'b0101: key_number <= 4'd4;
            4'b1001: key_number <= 4'd5;
            4'b0010: key_number <= 4'd6;
            4'b0110: key_number <= 4'd7;
            4'b1010: key_number <= 4'd8;
            default: key_number <= 4'd9;  // This key doesn't exist
        endcase
    end
endmodule
