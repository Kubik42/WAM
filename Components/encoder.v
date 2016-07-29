// 3-bit to 2-bit encoder

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module encoder(
	input [2:0] row,
	output reg [1:0] key
	);

	always @(*)
	begin: encode
		case(row)
			3'b100: key <= 2'd0;  // Row 1
			3'b010: key <= 2'd1;  // Row 2
			3'b001: key <= 2'd2;  // Row 3
			default: key <= 2'd3;
		endcase
	end
endmodule
