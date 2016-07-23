// 2-bit to 3-bit decoder

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module decoder(
	input [1:0] in,
	output reg [2:0] column
	);

	always @(*)
	begin: decode
		case (in)
			2'd0: column <= 110;
			2'd1: column <= 101;
			2'd2: column <= 011;
			default: column <= 111;
		endcase		
	end
endmodule
