module datapath (CLOCK_50, Rload_lfsr, Rshift, Rreset, Wreset, SW, incr_level, reset_level);
	input CLOCK_50;
	input Rload_lfsr; //Active high, load clock val into lfsr
	input Rshift; //Active high. Shift lfsr val's into control seq's
	input Rspeed; //Speed to shift control seq's (1 for 1Hz, 0 for 50MHz)
	input Rreset; //Reset random circuits. Active high
	input RateDivreset; //Reset rate dividers. Active high
	input Wreset; //Reset Mole WHACK FSM's. Active high
	input [7:0] SW; //Switches
	input incr_level; //Increments level on L to H transition
	input reset_level; //Active high reset of level.
	
	wire CLOCK_1Hz;
	RateDivider1Hz rd1hz(.CO(CLOCK_1Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_2Hz;
	RateDivider2Hz rd1hz(.CO(CLOCK_1Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_4Hz;
	RateDivider4Hz rd1hz(.CO(CLOCK_1Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_8Hz;
	RateDivider8Hz rd1hz(.CO(CLOCK_1Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_16Hz;
	RateDivider16Hz rd1hz(.CO(CLOCK_1Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_10Hz;
	RateDivider10Hz(.CO(CLOCK_10Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_20Hz;
	RateDivider20Hz(.CO(CLOCK_20Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_40Hz;
	RateDivider40Hz rd40hz (.CO(CLOCK_40Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_80Hz;
	RateDivider80Hz rd40hz (.CO(CLOCK_40Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_160Hz;
	RateDivider160Hz rd40hz (.CO(CLOCK_40Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire [7:0] ctrl;
	rand_module rm (.Rreset(Reset), .CLOCK_50(CLOCK_50), .CLOCK_1Hz(CLOCK_1Hz), .Rload_lfsr(Rload_lfsr), .Rshift(Rshift), .Rspeed(Rspeed), .ctrl(ctrl));

	wire [7:0] mole_hit;
	MoleWhackFSM8Way(.reset(Wreset), .CLOCK_50(CLOCK_50), .SW(SW) ,.mole_hit(mole_hit))
	
	reg [2:0] level;
	always @(posedge incr_level, posedge reset_level) begin 
		if(reset_level)
			level <= 3'b0;
		else 
			level <= level + 1'b1;
	end
	
	wire clock_wait;
	assign clock_wait = (level == 3'b000) CLOCK_2Hz? : ((level == 3'b001) ? CLOCK_4Hz : ((level == 3'b010) ? CLOCK_8Hz : ((level == 3'b011) ? CLOCK_16Hz : ((level == 3'b100) ? CLOCK_50 : 1'b1))));
	
	CompleteCount cc (reset_scores, reset_moles, clock, clock_wait, clockrL, control, mole_hit, Mheight, totalScore, totalRise);
endmodule

//***********************
//RATE DIVIDERS
//
//***********************
//Modified from Labs
module RateDivider1Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (1Hz for 50MHz input)
	
	reg [25:0] count; // 26 bits required.

	assign CO = (count == 26'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 26'd49999999;
		else if (count == 26'd0)
			count <= 26'd49999999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider2Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (1Hz for 50MHz input)
	
	reg [25:0] count; // 26 bits required.

	assign CO = (count == 26'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 26'd24999999;
		else if (count == 26'd0)
			count <= 26'd24999999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider4Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (1Hz for 50MHz input)
	
	reg [25:0] count; // 26 bits required.

	assign CO = (count == 26'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 26'd12499999;
		else if (count == 26'd0)
			count <= 26'd12499999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider8Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (1Hz for 50MHz input)
	
	reg [25:0] count; // 26 bits required.

	assign CO = (count == 26'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 26'd6249999;
		else if (count == 26'd0)
			count <= 26'd6249999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider16Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (1Hz for 50MHz input)
	
	reg [25:0] count; // 26 bits required.

	assign CO = (count == 26'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 26'd3124999;
		else if (count == 26'd0)
			count <= 26'd3124999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider10Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (1Hz for 50MHz input)
	
	reg [23:0] count; // 24 bits required.

	assign CO = (count == 24'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 24'd4999999;
		else if (count == 24'd0)
			count <= 24'd4999999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider20Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (1Hz for 50MHz input)
	
	reg [23:0] count; // 24 bits required.

	assign CO = (count == 24'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 24'd2499999;
		else if (count == 24'd0)
			count <= 24'd2499999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider40Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (40Hz for 50MHz input)
	
	reg [20:0] count; // 21 bits required.

	assign CO = (count == 21'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 21'd1249999;
		else if (count == 21'd0)
			count <= 21'd1249999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider80Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (80Hz for 50MHz input)
	
	reg [19:0] count; // 20 bits required.

	assign CO = (count == 20'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 20'd624999;
		else if (count == 20'd0)
			count <= 20'd624999;
		else
			count <= count - 1'b1;
	end	
endmodule

module RateDivider160Hz(CO, Clock, Areset);
	input Clock;
	input Areset; // synchronous active high reset (resets to start corresp to mode)
	output CO; // slowed clock output (80Hz for 50MHz input)
	
	reg [19:0] count; // 20 bits required.

	assign CO = (count == 20'b0) ? 1'b1:1'b0;
	
	always @(posedge Clock) begin
		if(Areset == 1'b1)
			count <= 20'd312499;
		else if (count == 20'd0)
			count <= 20'd312499;
		else
			count <= count - 1'b1;
	end	
endmodule

//*************************
//MOLE WHACK MODULES
//
//
//*************************
module MoleWhackFSM8Way(reset, CLOCK_50, SW ,mole_hit);
	input [7:0] SW;
	input CLOCK_50, reset;
	output [7:0]mole_hit;
	
	MoleWhackFSM (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[0]) ,.mole_hit(mole_hit[0]));
	MoleWhackFSM (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[1]) ,.mole_hit(mole_hit[1]));
	MoleWhackFSM (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[2]) ,.mole_hit(mole_hit[2]));
	MoleWhackFSM (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[3]) ,.mole_hit(mole_hit[3]));
	MoleWhackFSM (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[4]) ,.mole_hit(mole_hit[4]));
	MoleWhackFSM (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[5]) ,.mole_hit(mole_hit[5]));
	MoleWhackFSM (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[6]) ,.mole_hit(mole_hit[6]));
	MoleWhackFSM (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[7]) ,.mole_hit(mole_hit[7]));
endmodule

module MoleWhackFSM (reset, CLOCK_50, switch ,mole_hit);
	input reset, CLOCK_50, switch;
	output mole_hit;
	
	reg [1:0] state;
	
	localparam A = 2'b00, B = 2'b01, C = 2'b11;
	
	reg [1:0] next_state;
	always @(*) begin
		case (state)
			A: next_state = (switch == 1'b1) ? B:A;
			B: next_state = (switch == 1'b0) ? C:B;
			C: next_state = A;
		endcase
	end
	
	always @(posedge CLOCK_50) begin
		if (reset == 1'b1)
			state <= A;
		else 
			state <= next_state;
	end
	
	assign mole_hit = (state == C) ? 1'b1 : 1'b0;
	
endmodule


//*************************
//MOLE HEIGHT AND SCORE MODULES
//
//
//*************************
module CompleteCount(reset_scores, reset_moles, clock, clock_wait, clockrL, control, mole_hit, Mheight, totalScore, totalRise);
	input reset_moles; //active high reset
	input reset_scores; //asynchronous active high reset
	input clock;
	input clock_wait;
	input clockrL;
	input [7:0] control;
	input [7:0] mole_hit;

	output [39:0] Mheight;
	output [15:0] totalScore;
	output [15:0] totalRise;

	wire [7:0] hiding;
	
	wire [4:0] Mheight0;
	wire [4:0] Mheight1;
	wire [4:0] Mheight2;
	wire [4:0] Mheight3;
	wire [4:0] Mheight4;
	wire [4:0] Mheight5;
	wire [4:0] Mheight6;
	wire [4:0] Mheight7;

	wire [15:0] scoreCountToAdder0;
	wire [15:0] scoreCountToAdder1;
	wire [15:0] scoreCountToAdder2;
	wire [15:0] scoreCountToAdder3;
	wire [15:0] scoreCountToAdder4;
	wire [15:0] scoreCountToAdder5;
	wire [15:0] scoreCountToAdder6;
	wire [15:0] scoreCountToAdder7;

	wire [15:0] riseCountToAdder0;
	wire [15:0] riseCountToAdder1;
	wire [15:0] riseCountToAdder2;
	wire [15:0] riseCountToAdder3;
	wire [15:0] riseCountToAdder4;
	wire [15:0] riseCountToAdder5;
	wire [15:0] riseCountToAdder6;
	wire [15:0] riseCountToAdder7;

	wire [15:0] AdderConnecter0;
	wire [15:0] AdderConnecter1;
	wire [15:0] AdderConnecter2;
	wire [15:0] AdderConnecter3;
	wire [15:0] AdderConnecter4;
	wire [15:0] AdderConnecter5;
	wire [15:0] AdderConnecter6;
	wire [15:0] AdderConnecter7;
	wire [15:0] AdderConnecter8;
	wire [15:0] AdderConnecter9;
	wire [15:0] AdderConnecter10;
	wire [15:0] AdderConnecter11;

	rl mole0(.reset(reset_moles || mole_hit[0]), .CLOCK_50(clock), .CLOCK_RL(clockrL), .CLOCK_WAIT(clock_wait), .go(control[0]), .hiding(hiding[0]), .Mheight(Mheight0));
	rl mole1(.reset(reset_moles || mole_hit[1]), .CLOCK_50(clock), .CLOCK_RL(clockrL), .CLOCK_WAIT(clock_wait), .go(control[1]), .hiding(hiding[1]), .Mheight(Mheight1));
	rl mole2(.reset(reset_moles || mole_hit[2]), .CLOCK_50(clock), .CLOCK_RL(clockrL), .CLOCK_WAIT(clock_wait), .go(control[2]), .hiding(hiding[2]), .Mheight(Mheight2));
	rl mole3(.reset(reset_moles || mole_hit[3]), .CLOCK_50(clock), .CLOCK_RL(clockrL), .CLOCK_WAIT(clock_wait), .go(control[3]), .hiding(hiding[3]), .Mheight(Mheight3));
	rl mole4(.reset(reset_moles || mole_hit[4]), .CLOCK_50(clock), .CLOCK_RL(clockrL), .CLOCK_WAIT(clock_wait), .go(control[4]), .hiding(hiding[4]), .Mheight(Mheight4));
	rl mole5(.reset(reset_moles || mole_hit[5]), .CLOCK_50(clock), .CLOCK_RL(clockrL), .CLOCK_WAIT(clock_wait), .go(control[5]), .hiding(hiding[5]), .Mheight(Mheight5));
	rl mole6(.reset(reset_moles || mole_hit[6]), .CLOCK_50(clock), .CLOCK_RL(clockrL), .CLOCK_WAIT(clock_wait), .go(control[6]), .hiding(hiding[6]), .Mheight(Mheight6));
	rl mole7(.reset(reset_moles || mole_hit[7]), .CLOCK_50(clock), .CLOCK_RL(clockrL), .CLOCK_WAIT(clock_wait), .go(control[7]), .hiding(hiding[7]), .Mheight(Mheight7));
	
	assign Mheight = {Mheight0, Mheight1, Mheight2, Mheight3, Mheight4, Mheight5, Mheight6, Mheight7};

	scoreCount scoreMole0(.count(scoreCountToAdder0), .mole_hit(mole_hit[0]), .hiding(hiding[0]), .reset(reset_scores));
	scoreCount scoreMole1(.count(scoreCountToAdder1), .mole_hit(mole_hit[1]), .hiding(hiding[1]), .reset(reset_scores));
	scoreCount scoreMole2(.count(scoreCountToAdder2), .mole_hit(mole_hit[2]), .hiding(hiding[2]), .reset(reset_scores));
	scoreCount scoreMole3(.count(scoreCountToAdder3), .mole_hit(mole_hit[3]), .hiding(hiding[3]), .reset(reset_scores));
	scoreCount scoreMole4(.count(scoreCountToAdder4), .mole_hit(mole_hit[4]), .hiding(hiding[4]), .reset(reset_scores));
	scoreCount scoreMole5(.count(scoreCountToAdder5), .mole_hit(mole_hit[5]), .hiding(hiding[5]), .reset(reset_scores));
	scoreCount scoreMole6(.count(scoreCountToAdder6), .mole_hit(mole_hit[6]), .hiding(hiding[6]), .reset(reset_scores));
	scoreCount scoreMole7(.count(scoreCountToAdder7), .mole_hit(mole_hit[7]), .hiding(hiding[7]), .reset(reset_scores));
	
	DecimalAdder4Dig scoreAdd0(.A(scoreCountToAdder0), .B(scoreCountToAdder1), .out(AdderConnecter0));
	DecimalAdder4Dig scoreAdd1(.A(AdderConnecter0), .B(scoreCountToAdder2), .out(AdderConnecter1));
	DecimalAdder4Dig scoreAdd2(.A(AdderConnecter1), .B(scoreCountToAdder3), .out(AdderConnecter2));
	DecimalAdder4Dig scoreAdd3(.A(AdderConnecter2), .B(scoreCountToAdder4), .out(AdderConnecter3));
	DecimalAdder4Dig scoreAdd4(.A(AdderConnecter3), .B(scoreCountToAdder5), .out(AdderConnecter4));
	DecimalAdder4Dig scoreAdd5(.A(AdderConnecter4), .B(scoreCountToAdder6), .out(AdderConnecter5));
	DecimalAdder4Dig scoreAdd6(.A(AdderConnecter5), .B(scoreCountToAdder7), .out(totalScore));

	riseCount riseMole0(.count(riseCountToAdder0), .control(control[0]), .hiding(hiding[0]), .reset(reset_scores));
	riseCount riseMole1(.count(riseCountToAdder1), .control(control[1]), .hiding(hiding[1]), .reset(reset_scores));
	riseCount riseMole2(.count(riseCountToAdder2), .control(control[2]), .hiding(hiding[2]), .reset(reset_scores));
	riseCount riseMole3(.count(riseCountToAdder3), .control(control[3]), .hiding(hiding[3]), .reset(reset_scores));
	riseCount riseMole4(.count(riseCountToAdder4), .control(control[4]), .hiding(hiding[4]), .reset(reset_scores));
	riseCount riseMole5(.count(riseCountToAdder5), .control(control[5]), .hiding(hiding[5]), .reset(reset_scores));
	riseCount riseMole6(.count(riseCountToAdder6), .control(control[6]), .hiding(hiding[6]), .reset(reset_scores));
	riseCount riseMole7(.count(riseCountToAdder7), .control(control[7]), .hiding(hiding[7]), .reset(reset_scores));

	DecimalAdder4Dig riseAdd0(.A(riseCountToAdder0), .B(riseCountToAdder1), .out(AdderConnecter6));
	DecimalAdder4Dig riseAdd1(.A(AdderConnecter6), .B(riseCountToAdder2), .out(AdderConnecter7));
	DecimalAdder4Dig riseAdd2(.A(AdderConnecter7), .B(riseCountToAdder3), .out(AdderConnecter8));
	DecimalAdder4Dig riseAdd3(.A(AdderConnecter8), .B(riseCountToAdder4), .out(AdderConnecter9));
	DecimalAdder4Dig riseAdd4(.A(AdderConnecter9), .B(riseCountToAdder5), .out(AdderConnecter10));
	DecimalAdder4Dig riseAdd5(.A(AdderConnecter10), .B(riseCountToAdder6), .out(AdderConnecter11));
	DecimalAdder4Dig riseAdd6(.A(AdderConnecter11), .B(riseCountToAdder7), .out(totalRise));

endmodule
	

//change clocks of both counters to the and of hiding and control
module riseCount(count, control, hiding, reset);
	output [15:0] count;
	input reset, hiding, control;
	
	DecimalCounter4Dig dc4g (.count(count), .clock(control && hiding), .reset(reset));
endmodule


module scoreCount(count, mole_hit, hiding, reset);
	output [15:0] count;
	input reset, hiding, mole_hit;
	
	DecimalCounter4Dig dc4g (.count(count), .clock(mole_hit && ~hiding), .reset(reset));
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
	
	always @(posedge clock, posedge reset) begin
		if(reset == 1'b1)
			ones <= 4'b0;
		else if(ones == 4'd9)
			ones <= 4'b0;
		else
			ones <= ones + 1'b1;
	end
	
	always @(posedge clock, posedge reset) begin
		if(reset == 1'b1)
			tens <= 4'b0;
		else if(ones == 4'd9 && tens == 4'd9)
			tens <= 4'b0;
		else if(ones == 4'd9)
			tens <= tens + 1'b1;
	end
	
	always @(posedge clock, posedge reset) begin
		if(reset == 1'b1 )
			hundreds <= 4'b0;
		else if({hundreds, tens, ones} == 12'b1001_1001_1001)
			hundreds <= 4'b0;
		else if(tens == 4'd9 && ones == 4'd9)
			hundreds <= hundreds + 1'b1;
	end
	
	always @(posedge clock, posedge reset) begin
		if(reset == 1'b1)
			thousands <= 4'b0;
		if({thousands, hundreds, tens, ones} == 16'b1001_1001_1001_1001)
			thousands <= 4'b0;
		else if(hundreds == 4'd9 && tens == 4'd9 && ones == 4'd9)
			thousands <= thousands + 1'b1;
	end

endmodule


module rl (reset, go, CLOCK_50, CLOCK_WAIT, CLOCK_RL, Mheight, hiding);
	input reset, go, CLOCK_50, CLOCK_RL, CLOCK_WAIT;
	
	wire Mreset_height;
	wire Mreset_wait;
	wire Mheight_en;
	wire Mheight_incr;
	wire [2:0] Mwait;
	output [4:0] Mheight;
	output hiding;
	
	MoleRL  mrl(.Mwait(Mwait), .Mheight(Mheight), .CLOCK_WAIT(CLOCK_WAIT), .CLOCK_RL(CLOCK_RL), .Mreset_wait(Mreset_wait), .Mheight_en(Mheight_en), .Mreset_height(Mreset_height), .Mheight_incr(Mheight_incr));
	MoleRLControlFSM mrlfsm (.Mgo(go), .reset(reset), .CLOCK_50(CLOCK_50), .hiding(hiding), .Mwait(Mwait), .Mheight(Mheight), .Mreset_wait(Mreset_wait), .Mheight_en(Mheight_en), .Mreset_height(Mreset_height), .Mheight_incr(Mheight_incr));
endmodule

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


//*************************
//RANDOMIZATION MODULES
//
//
//*************************

module rand_module (Rreset, CLOCK_50, CLOCK_1Hz, Rload_lfsr, Rshift, Rspeed, ctrl);
	input Rreset, CLOCK_1Hz, CLOCK_50, Rload_lfsr, Rshift, Rspeed; //Active high reset
	output [7:0] ctrl;

	wire [15:0] count;
	counter16bit c16b(.count(count), .CLOCK_50(CLOCK_50), .reset(Rreset));
	
	wire rand_lfsr;
	LFSR lfsr (.load_val(count), .Rload_lfsr(Rload_lfsr), .Rshift(Rshift), .CLOCK_50(CLOCK_50), .reset(Rreset), .out(rand_lfsr));
	
	controlSeq csq (.clock(CLOCK_50), .shift((Rspeed == 1'b1) ? CLOCK_1Hz : 1'b1), .load_val(rand_lfsr), .reset(Rreset), .ctrl(ctrl));
endmodule

module counter16bit (count, CLOCK_50, reset);
	input CLOCK_50, reset;
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