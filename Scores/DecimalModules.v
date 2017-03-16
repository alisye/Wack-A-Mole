//output will not exceed 9000
module DecimalAdder4Dig (A, B, out);
	input [15:0] A; //ones, tens, hundreds, thousands
	input [15:0] B; //ones, tens, hundreds, thousands
	output[15:0] out; //ones, tens, hundreds, thousands 
	
	wire c1, c2, c3, c4;
	DigitAdder da4 (.A(A[3:0]), .B(B[3:0]), .carry_in(c3), .out(out[3:0]), .carry_out(c4)); //thousands
	DigitAdder da3 (.A(A[7:4]), .B(B[7:4]), .carry_in(c2), .out(out[7:4]), .carry_out(c3)); //hundreds
	DigitAdder da2 (.A(A[11:8]), .B(B[11:8]), .carry_in(c1), .out(out[11:8]), .carry_out(c2)); //tens
	DigitAdder da1 (.A(A[15:12]), .B(B[15:12]), .carry_in(1'b0), .out(out[15:12]), .carry_out(c1));//ones
endmodule

module DigitAdder(A, B, carry_in, out, carry_out);
	input [3:0] A;
	input [3:0] B;
	input carry_in;
	output reg [3:0] out;
	output reg carry_out;
	
	always@(*) begin
		if(A+B+carry_in < 5'd10)
			begin
			out[3:0] = A+B+carry_in;
			carry_out = 1'b0;
			end
		else 
			begin
			out[3:0] = A+B+carry_in+4'd6;
			carry_out = 1'b1;
			end
	end
endmodule

module DecimalCounter4Dig(count, clock, reset);
	output [15:0] count;
	input clock;
	input reset;
	
	reg [3:0] ones;
	reg [3:0] hundreds;
	reg [3:0] tens;
	reg [3:0] thousands;
	
	assign count = {ones, tens, hundreds, thousands};
	
	always @(posedge clock) begin
		if(reset == 1'b1)
			ones <= 4'b0;
		else if(ones == 4'd9)
			ones <= 4'b0;
		else
			ones <= ones + 1'b1;
	end
	
	always @(posedge clock) begin
		if(reset == 1'b1)
			tens <= 4'b0;
		else if(ones == 4'd9 && tens == 4'd9)
			tens <= 4'b0;
		else if(ones == 4'd9)
			tens <= tens + 1'b1;
	end
	
	always @(posedge clock) begin
		if(reset == 1'b1 )
			hundreds <= 4'b0;
		else if({hundreds, tens, ones} == 12'b1001_1001_1001)
			hundreds <= 4'b0;
		else if(tens == 4'd9 && ones == 4'd9)
			hundreds <= hundreds + 1'b1;
	end
	
	always @(posedge clock) begin
		if(reset == 1'b1)
			thousands <= 4'b0;
		if({thousands, hundreds, tens, ones} == 16'b1001_1001_1001_1001)
			thousands <= 4'b0;
		else if(hundreds == 4'd9 && tens == 4'd9 && ones == 4'd9)
			thousands <= thousands + 1'b1;
	end

endmodule