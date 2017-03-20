module test(SW, HEX);	
	input [3:0]SW;
	output [6:0]HEX;

	show_level(SW, HEX);

endmodule


module show_level(level, segments);
	input [3:0]level;
	output reg [6:0]segments;

	always @(*)
		case (level)
			4'b0000: segments = 7'b100_0000;
			4'b0001: segments = 7'b111_1001;
			4'b0010: segments = 7'b010_0100;
			4'b0011: segments = 7'b011_0000;
			4'b0100: segments = 7'b001_1001;
			4'b0101: segments = 7'b001_0010;
			4'b0110: segments = 7'b000_0010;
			4'b0111: segments = 7'b111_1000;
			4'b1000: segments = 7'b000_0000;
			4'b1001: segments = 7'b001_1000;
			default: segments = 7'b111_1111;
		endcase
endmodule
