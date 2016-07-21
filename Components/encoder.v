// 3-bit to 2-bit encoder

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module encoder(
	input [2:0] row,
	output reg [1:0] key
	);

	always @(*)
	begin: encode
		case(row)
			110: key <= 2'd0;
			101: key <= 2'd1;
			011: key <= 2'd2;
			default: key <= 2'd3;
		endcase
	end
endmodule
