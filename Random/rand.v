module rand (Rreset, CLOCK_50, CLOCK_1Hz, Rload_lfsr, Rshift, ctrl, Rspeed);
	input Rreset, CLOCK_1Hz, CLOCK_50, Rload_lfsr, Rshift, Rspeed;
	output [7:0] ctrl;

	wire [15:0] count;
	counter16bit c16b(.count(count), .CLOCK_50(CLOCK_50), .reset(Rreset));
	
	wire rand_lfsr;
	LFSR lfsr (.load_val(count), .Rload_lfsr(Rload_lfsr), .Rshift(Rshift), .CLOCK_50(CLOCK_50), .reset(Rreset), .out(rand_lfsr));
	
	controlSeq csq (.clock(CLOCK_50), .shift((Rspeed == 1'b1) CLOCK_1Hz ? 1'b1:), .load_val(rand_lfsr), .reset(Rreset), .ctrl(ctrl));
endmodule

module counter16bit (count, CLOCK_50, reset);
	output reg [15:0] count;
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b1)
			count <= 16'b0;
		else
			count <= count + 1'b1;
	end
endmodule

module LFSR (load_val, Rload_lfsr, Rshift, CLOCK_50, reset, out);
	input [15:0] load_val;
	input Rload_lfsr, Rshift, CLOCK_50, reset;
	output out;
	
	reg [15:0] mem;
	assign out = mem[0];
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b1)
			mem <= 16'b0;
		else if (Rload_lfsr == 1'b1)
			mem <= load_val;
		else if (Rshift == 1'b1)
			mem <= {mem[0] ^ mem[2] ^ mem [3] ^ mem[5] ,mem} >> 1;
	end
endmodule

module controlSeq (clock, shift, load_val, reset, ctrl);
	input clock, shift, load_val, reset;
	output [7:0]ctrl;

	reg [479:0] mem;
	
	assign ctrl [0] = mem[59];
	assign ctrl [1] = mem[119];
	assign ctrl [2] = mem[179];
	assign ctrl [3] = mem[239];
	assign ctrl [4] = mem[299];
	assign ctrl [5] = mem[359];
	assign ctrl [6] = mem[419];
	assign ctrl [7] = mem[479];
	
	always @(posedge clock, posedge reset) begin
		if(reset == 1'b1)
			mem <= 480'b0;
		else if(shift == 1'b1)
			begin 
			 mem <= {load_val, mem} >> 1;
			end
	end
endmodule