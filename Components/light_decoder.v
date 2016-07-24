// light position decoder

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module light_decoder(
	input [3:0] in,
	output reg [3:0] coordinates // [column row] format
	);
	
	wire [3:0] row2;
	assign row2 = (in[3:0] - 4'd0011);
	
	wire [3:0] row3;
	assign row3 = (in[3:0] - 4'd0110);
	
	always @(*)
	begin
		if (in <= 4'd2) begin // Row 1
			coordinates[1:0] <= 2'b00; // Row
			coordinates[3:2] <= in[1:0]; // Column
		end
		else if (4'd3 <= in && in <= 4'd5) begin // Row 2
			coordinates[1:0] <= 2'b01;
			coordinates[3:2] <= row2[1:0];
		end
		else if (4'd6 <= in && in <= 4'd8) begin // Row 3
			coordinates[1:0] <= 2'b10;
			coordinates[3:2] <= row3[1:0];
		end
	end
endmodule
