`timescale 1ns / 1ns // `timescale time_unit/time_precision

// Models a binary to decimal decoder for hex display

// binary[3:0] - data inputs

// hex[6:0] - output display

module bdd(
    input [3:0] binary,
    input enable,
    input reset,
    output reg [6:0] hex
    );

    always @(*)
        if (~reset)
            hex <= 7'b1111111;
        else if (enable) begin
            case (binary)
                4'h0: hex <= 7'b1000000;
                4'h1: hex <= 7'b1111001;
                4'h2: hex <= 7'b0100100;
                4'h3: hex <= 7'b0110000;
                4'h4: hex <= 7'b0011001;
                4'h5: hex <= 7'b0010010;
                4'h6: hex <= 7'b0000010;
                4'h7: hex <= 7'b1111000;
                4'h8: hex <= 7'b0000000;
                4'h9: hex <= 7'b0010000;
                default: hex <= 7'b1111111;
            endcase
        end
endmodule
