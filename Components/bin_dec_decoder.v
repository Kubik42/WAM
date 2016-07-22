`timescale 1ns / 1ns // `timescale time_unit/time_precision

// Models a binary to decimal decoder for hex display

// binary[3:0] data inputs

// hex[6:0] output display

module bdd(
    input [3:0] binary,
    output reg [6:0] hex
    );

    always @(binary)
    	case (binary)
			4'h0: hex <= 7'b0111111;
			4'h1: hex <= 7'b0000110;
			4'h2: hex <= 7'b1011011;
			4'h3: hex <= 7'b1001111;
			4'h4: hex <= 7'b1100110;
			4'h5: hex <= 7'b1101101;
			4'h6: hex <= 7'b1111101;
			4'h7: hex <= 7'b0000111;
			4'h8: hex <= 7'b1111111;
			4'h9: hex <= 7'b1101111;
			default: hex = 7'b1111111;
		endcase

endmodule
