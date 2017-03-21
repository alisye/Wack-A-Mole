module test(KEY, CLOCK_50,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
		);
	input [3:0]KEY;
	input CLOCK_50;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
	wire [4:0] counter;
		
	wire [39:0]  temp_val = {counter [4:0] , 35'b00010_00100_01000_10000_10011_10100_00100};
	wire slowed;
	
	wire slower;
	RateDivider2 rd1Hz(.CO(slower), .Clock(CLOCK_50), .Areset(resetn));
	
	testRL trl (~KEY[3], ~KEY[2], CLOCK_50, slower ,slowed, counter);
	
	wire [15:0] decimalcount;
	DecimalCounter4Dig dc4d (.count(decimalcount), .clock(slowed), .reset(~KEY[1]));
	
	RateDivider rd40(.CO(slowed), .Clock(CLOCK_50), .Areset(resetn));
		
	MoleAndScore mas(.x(x), .y(y), .col(colour), .plot(writeEn), .molePositions(temp_val), .total(decimalcount), .score(16'b0001_0010_0011_0100), .CLOCK_40(slowed), .CLOCK_50(CLOCK_50), .reset(~resetn));
	
endmodule

module testRL (reset, go, CLOCK_50, CLOCK_WAIT, CLOCK_RL, Mheight);
	input reset, go, CLOCK_50, CLOCK_RL, CLOCK_WAIT;
	
	wire Mreset_height;
	wire Mreset_wait;
	wire Mheight_en;
	wire Mheight_incr;
	wire [2:0] Mwait;
	output [4:0] Mheight;
	
	wire hiding;
	
	MoleRL  mrl(.Mwait(Mwait), .Mheight(Mheight), .CLOCK_WAIT(CLOCK_WAIT), .CLOCK_RL(CLOCK_RL), .Mreset_wait(Mreset_wait), .Mheight_en(Mheight_en), .Mreset_height(Mreset_height), .Mheight_incr(Mheight_incr));
	MoleRLControlFSM mrlfsm (.Mgo(go), .reset(reset), .CLOCK_50(CLOCK_50), .hiding(hiding), .Mwait(Mwait), .Mheight(Mheight), .Mreset_wait(Mreset_wait), .Mheight_en(Mheight_en), .Mreset_height(Mreset_height), .Mheight_incr(Mheight_incr));
endmodule

module MoleRL (Mwait, Mheight, CLOCK_WAIT, CLOCK_RL, Mreset_wait, Mheight_en, Mreset_height, Mheight_incr);
	input Mreset_height;
	input Mreset_wait;
	input Mheight_en;
	input Mheight_incr;
	input CLOCK_WAIT;
	input CLOCK_RL;
	
	output reg [2:0] Mwait;
	output reg [4:0] Mheight;
	
	always@(posedge CLOCK_WAIT, posedge Mreset_wait) begin
		if(Mreset_wait == 1'b1)
			Mwait <= 3'b0;
		else
			Mwait <= Mwait + 1'b1;
	end
	
	always@(posedge CLOCK_RL, posedge Mreset_height) begin
		if(Mreset_height == 1'b1)
			Mheight <= 3'b0;
		else
			begin
				if(Mheight_en == 1'b1 && Mheight_incr == 1'b1 && Mheight == 5'd20)
					Mheight <= 5'd20;
				else if (Mheight_en == 1'b1 && Mheight_incr == 1'b1)
					Mheight <= Mheight + 1'b1;
				else if(Mheight_en == 1'b1 && Mheight_incr == 1'b0 && Mheight == 5'b0)
					Mheight <= 5'b0;
				else if (Mheight_en == 1'b1 && Mheight_incr == 1'b0)
					Mheight <= Mheight - 1'b1;
			end
	end

endmodule

module MoleRLControlFSM (Mgo, reset, CLOCK_50, hiding, Mwait, Mheight, Mreset_wait, Mheight_en, Mreset_height, Mheight_incr);
	input [2:0] Mwait;
	input [4:0] Mheight;
	input reset;
	input CLOCK_50;
	input Mgo; //This mole should start to rise
	
	output reg Mreset_height;
	output reg Mreset_wait;
	output reg Mheight_en;
	output reg Mheight_incr;
	output reg hiding;
	
	reg [1:0] curr_state;
	reg [1:0] next_state;
	
	localparam  A = 2'b00,
				B = 2'b01,
				C = 2'b11,
				D = 2'b10;
				
	//Output
	always@(*) begin
		Mreset_height = 1'b0;
		Mreset_wait = 1'b0;
		Mheight_en = 1'b0;
		Mheight_incr = 1'b0;
		hiding = 1'b0;
		
		case (curr_state)
			A:  begin
					hiding = 1'b1;
					Mreset_height = 1'b1;
					Mreset_wait = 1'b1;
				end
			B:  begin
					Mreset_wait = 1'b1;
					Mheight_en = 1'b1;
					Mheight_incr = 1'b1;
				end 
			D:  begin 
					Mreset_wait = 1'b1;
					Mheight_en = 1'b1;
				end
			//C stays all 0
		endcase
	end
	
	
	//Next state
	always @(*) begin
		case(curr_state)
			A: next_state = (Mgo == 1'b1) ? B:A;
			B: next_state = (Mheight == 5'd20) ? C:B;
			C: next_state = (Mwait == 3'b100) ? D:C;
			D: next_state = (Mheight == 5'b0) ? A:D;
		endcase 
	end
	
	//State transitions
	always @(posedge CLOCK_50) begin
		if(reset == 1'b1)
			curr_state <= A;
		else 
			curr_state <= next_state;
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


//temporarily reused
module RateDivider(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active low reset (resets to start corresp to mode)
	output CO; // slowed clock output (40Hz for 50MHz input)
	
	reg [20:0] count; // 21 bits required.

	assign CO = (count == 21'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b0)
			count <= 21'd1249999;
		else if (count == 21'd0)
			count <= 21'd1249999;
		else
			count <= count - 1'b1;
	end	
endmodule

//temporarily reused
module RateDivider2(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active low reset (resets to start corresp to mode)
	output CO; // slowed clock output (1Hz for 50MHz input)
	
	reg [25:0] count; // 26 bits required.

	assign CO = (count == 26'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b0)
			count <= 26'd49999999;
		else if (count == 21'd0)
			count <= 26'd49999999;
		else
			count <= count - 1'b1;
	end	
endmodule

//Note: should probably latch total and score. Will try w/o and add latches if doesn't work.
module MoleAndScore(x, y, col, plot, molePositions, total, score, CLOCK_40, CLOCK_50, reset);
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] col;
	output reg plot;
	
	input [39:0] molePositions; //5 bits ea. for 8 moles
	input [15:0] total;//4 4bit decimal values
	input [15:0] score;//4 4bit decimal values
	input CLOCK_40; //40Hrtz clock
	input CLOCK_50; //50MHz clock
	input reset;
	
	localparam  STOP_VAL = 5'b10001,
				TS = 5'b01000;
	
	reg [4:0] curr_obj; // 0 to STOP_VAL.
	reg [4:0] prev_curr_obj;
	reg [8:0] moleYX;
	reg [8:0] pastmoleYX;
	reg [4:0] currMoleShift;
	reg go;
	
	reg [2:0] digX;
	reg [2:0] pastdigX;
	reg [3:0] digY;
	reg [3:0] pastdigY;
	reg [5:0] addressdig;
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b1 || go == 1'b0 || curr_obj[4:0] < 5'b01001)
			begin
			digX <= 3'b0;
			pastdigX <= 3'b0;
			
			digY <= 4'b0;
			pastdigY <= 4'b0;
			
			addressdig <= 6'b0;
			end
		else if (go == 1'b1 && digX == 3'd5 && digY == 4'd9)
			begin
			pastdigX <= digX;
			digX <= 3'b0; //reset at max
			
			pastdigY <= digY;
			digY <= 4'b0; //reset at max
			
			addressdig <= 6'b0; //reset at max
			end
		else if (go == 1'b1 && digX == 3'd5)
			begin
			pastdigX <= digX;
			digX <= 3'b0; //reset at max
			
			pastdigY <= digY;
			digY <= digY + 1'b1;
			
			addressdig <= addressdig + 1'b1;
			end
		else if (go == 1'b1)
			begin
			pastdigX <= digX;
			digX <= digX + 1'b1; //incr if curr_obj is a digit
			
			pastdigY <= digY;
			
			addressdig <= addressdig + 1'b1;
			end
	end
	
	reg [3:0] currdig;
	always @(*) begin
		case (curr_obj)
			5'b01001: currdig = total [3:0];
			5'b01010: currdig = total [7:4];
			5'b01011: currdig = total [11:8];
			5'b01100: currdig = total [15:12];
			5'b01101: currdig = score [3:0];
			5'b01110: currdig = score [7:4];
			5'b01111: currdig = score [11:8];
			5'b10000: currdig = score [15:12];
			default: currdig = 4'b1111;
		endcase
	end
	
	wire [2:0] delayeddig;
	digit_info di (.digit(currdig), .address(addressdig), .clock(CLOCK_50), .q(delayeddig), .reset(reset));
	
	
	reg [3:0] tsX;
	reg [4:0] tsY;
	reg [3:0] pasttsX;
	reg [4:0] pasttsY;
	reg [7:0] addressts;
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b1 || go == 1'b0 || curr_obj[4:0] != TS)
			begin
			tsX <= 4'b0;
			pasttsX <= 4'b0;
			
			tsY <= 5'b0;
			pasttsY <= 5'b0;
			
			addressts <= 7'b0;
			end
		else if (go == 1'b1 && curr_obj[4:0] == TS && tsX == 4'd9)
			begin
			pasttsX <= tsX;
			tsX <= 4'b0; //reset at max
			
			pasttsY <= tsY;
			tsY <= tsY + 1'b1;
			
			addressts <= addressts + 1'b1;
			end
		else if (go == 1'b1 && curr_obj[4:0] == TS)
			begin
			pasttsX <= tsX;
			tsX <= tsX + 1'b1; //incr if curr_obj is a TS scoreboard
			
			pasttsY <= tsY;
			
			addressts <= addressts + 1'b1;
			end
	end
	
	wire [2:0] delayedTS;
	RamTS rts (.address(addressts), .clock(CLOCK_50), .data(3'b0), .wren(1'b0), .q(delayedTS));
	
	always @(*) begin
		case (curr_obj)
			5'b00000:currMoleShift = molePositions[4:0];
			5'b00001:currMoleShift = molePositions[9:5];
			5'b00010:currMoleShift = molePositions[14:10];
			5'b00011:currMoleShift = molePositions[19:15];
			5'b00100:currMoleShift = molePositions[24:20];
			5'b00101:currMoleShift = molePositions[29:25];
			5'b00110:currMoleShift = molePositions[34:30];
			5'b00111:currMoleShift = molePositions[39:35];
			default: currMoleShift = 5'b0;
		endcase
	end
	
	wire [9:0] mole_address;
	assign mole_address = moleYX + 5'b10000*currMoleShift;
	
	wire [2:0] delayedMoleImage;
	Mole3Ram m3r (.address(mole_address), .clock(CLOCK_50), .data(3'b000), .wren(1'b0), .q(delayedMoleImage));
	
	always @(posedge CLOCK_40, posedge CLOCK_50) begin
		if(CLOCK_40 == 1'b1)
			begin
			go <= 1'b1;
			plot <= go;
			end
		else if(reset == 1'b1)
			begin
			go <= 1'b1;
			plot <= 1'b0;
			end
		else if (prev_curr_obj == STOP_VAL)// cond b/f
			begin
			go <= 1'b0;
			plot <= 1'b0;
			end
		else
			plot <= go;
	end
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b1 || go == 1'b0 || curr_obj[4:3] != 2'b00)
			begin
			moleYX <= 8'b0;
			pastmoleYX <= 8'b0;
			end
		else if (go == 1'b1 && curr_obj[4:3] == 2'b00 && moleYX == 9'b10011_1111)
			begin
			pastmoleYX <= moleYX;
			moleYX <= 8'b0; //reset at max
			end
		else if (go == 1'b1 && curr_obj[4:3] == 2'b00)
			begin
			pastmoleYX <= moleYX;
			moleYX <= moleYX + 1'b1; //incr if curr_obj is a mole
			end
	end
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b1 || go == 1'b0)
			curr_obj <= 5'b0;
		else if (moleYX == 9'b10011_1111)// counters zero out of their turn
			curr_obj <= curr_obj + 1'b1;
		else if (tsX == 4'd9 && tsY == 5'd21)
			curr_obj <= curr_obj + 1'b1;
		else if (digX == 3'd5 && digY == 4'd9)
			curr_obj <= curr_obj + 1'b1;
		//no cases for 10001 and higher
	end 
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b1 || go == 1'b0)
			prev_curr_obj <= 5'b0;
		else
			prev_curr_obj <= curr_obj;
	end
	
	always @(*) begin
		if(prev_curr_obj[4:3] == 2'b00)
			begin
				case(prev_curr_obj[2:0])
					3'b000: x = pastmoleYX[3:0] + 8'd2;
					3'b001: x = pastmoleYX[3:0] + 8'd20;
					3'b010: x = pastmoleYX[3:0] + 8'd38;
					3'b011: x = pastmoleYX[3:0] + 8'd56;
					3'b100: x = pastmoleYX[3:0] + 8'd74;
					3'b101: x = pastmoleYX[3:0] + 8'd92;
					3'b110: x = pastmoleYX[3:0] + 8'd110;
					3'b111: x = pastmoleYX[3:0] + 8'd128;
				endcase
			end
		else if(prev_curr_obj[4:0] == TS)
			x = 8'd58 + pasttsX;
		else if(prev_curr_obj > 5'b01000 && prev_curr_obj < STOP_VAL)
			begin
				case(prev_curr_obj)
					5'b01001: x = pastdigX[2:0] + 8'd70;
					5'b01010: x = pastdigX[2:0] + 8'd78;
					5'b01011: x = pastdigX[2:0] + 8'd86;
					5'b01100: x = pastdigX[2:0] + 8'd94;
					5'b01101: x = pastdigX[2:0] + 8'd70;
					5'b01110: x = pastdigX[2:0] + 8'd78;
					5'b01111: x = pastdigX[2:0] + 8'd86;
					5'b10000: x = pastdigX[2:0] + 8'd94;
					default: x = 8'b11111111;
				endcase
			end
		else
			x = 8'b0;
	end
	
	always @(*) begin
		if(prev_curr_obj[4:3] == 2'b00)
				y [6:0]= 7'd100 + pastmoleYX[8:4];
		else if(prev_curr_obj[4:0] == TS)
			y = 7'd20 + pasttsY;
		else if(prev_curr_obj > 5'b01000 && prev_curr_obj < 5'b01101)
			y = 7'd20 + pastdigY;
		else if (prev_curr_obj < STOP_VAL)
			y = 7'd32 + pastdigY;	
		else
			y [6:0]= 7'b0;
	end
	
	always @(*) begin
		if(prev_curr_obj[4:3] == 2'b00)
				col [2:0] = delayedMoleImage[2:0];
		else if(prev_curr_obj[4:0] == TS)
			col [2:0] = delayedTS[2:0];
		else if(prev_curr_obj > TS && prev_curr_obj < STOP_VAL)
			col [2:0] = delayeddig;
		else
			col [2:0] = 3'b0;
	end

endmodule

//Note: make sure to register input for which #'s
//Note: 1 cycle delay from address to q
//Note: reset and let some clock cycles pass (also, address must change on same clock)
module digit_info(digit, address, clock, q, reset);
	input	[3:0] digit;
	input	[5:0] address;
	input	  clock;
	input reset;
	output reg [2:0] q;
	
	reg [3:0] prev_digit;
	
	wire [2:0] q0, q1, q2, q3, q4, q5, q6, q7, q8, q9;
	
	Ram0 r0 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q0));
	Ram1 r1 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q1));
	Ram2 r2 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q2));
	Ram3 r3 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q3));
	Ram4 r4 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q4));
	Ram5 r5 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q5));
	Ram6 r6 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q6));
	Ram7 r7 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q7));
	Ram8 r8 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q8));
	Ram9 r9 (.address(address), .clock(clock), .data(3'b0), .wren(1'b0), .q(q9));
	
	always @(posedge clock) begin
		if(reset == 1'b1)
			prev_digit <= 4'b1111;
		else
			prev_digit <= digit;
	end
	
	always @(*) begin
		case(prev_digit)
			4'b0000: q = q0;
			4'b0001: q = q1;
			4'b0010: q = q2;
			4'b0011: q = q3;
			4'b0100: q = q4;
			4'b0101: q = q5;
			4'b0110: q = q6;
			4'b0111: q = q7;
			4'b1000: q = q8;
			4'b1001: q = q9;
			default: q = 3'b0;
		endcase
	end

endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram0 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "0.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram1 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "1.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram2 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "2.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram3 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "3.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram4 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "4.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram5 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "5.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram6 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "6.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram7 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "7.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram8 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "8.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Ram9 (
	address,
	clock,
	data,
	wren,
	q);

	input	[5:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "9.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 60,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 6,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Mole3Ram (
	address,
	clock,
	data,
	wren,
	q);

	input	[9:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "Mole3.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 640,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 10,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module RamTS (
	address,
	clock,
	data,
	wren,
	q);

	input	[7:0]  address;
	input	  clock;
	input	[2:0]  data;
	input	  wren;
	output	[2:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [2:0] sub_wire0;
	wire [2:0] q = sub_wire0[2:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "TS.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 220,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 8,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


endmodule