module wam(SW, KEY, CLOCK_50,
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
	input [9:0] SW;
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
		
		datapath dp (.plot(writeEn), .x(x), .y(y), .col(colour), .CLOCK_50(CLOCK_50), .Rload_lfsr(~KEY[2]), .Rshift(1'b1), .Rspeed(1'b1), .Rreset(~KEY[1]), .RateDivreset(~KEY[1]), .Wreset(~KEY[1]), .SW(SW), .incr_level(1'b0), .reset_level(KEY[1]), .CReset_score(~KEY[1]), .CReset_moles(~KEY[1]), .Cenable_ctrl(1'b1), .Gmas_reset(~KEY[1]), .Glev_reset(~KEY[1]), .GVideo_source(2'b0));
		
endmodule

module datapath (plot, x, y, col, CLOCK_50, Rload_lfsr, Rshift, Rspeed, Rreset, RateDivreset, Wreset, SW, incr_level, reset_level, CReset_score, CReset_moles, Cenable_ctrl, Gmas_reset, Glev_reset, GVideo_source);
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
	input CReset_score; //Active high reset of total and score
	input CReset_moles; //Active high reset of mole position
	//TODO Add enable for counter to prevent increase during random generation
	//(or mux for control)
	input Cenable_ctrl; //Zero connects ctrl to 0 in mole score circuits.
	input Gmas_reset; //Active high Mole And Score graphics reset;
	input Glev_reset; //Active ***!!LOW!!*** level graphics reset.
	input [2:0] GVideo_source; //0 for MAS, 1 for LEV, 2 for CLR
	
	
	output reg plot;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] col;
	
	wire CLOCK_1Hz;
	RateDivider1Hz rd1hz(.CO(CLOCK_1Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_2Hz;
	RateDivider2Hz rd2hz(.CO(CLOCK_2Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_4Hz;
	RateDivider4Hz rd4hz(.CO(CLOCK_4Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_8Hz;
	RateDivider8Hz rd8hz(.CO(CLOCK_8Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_16Hz;
	RateDivider16Hz rd16hz(.CO(CLOCK_16Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_10Hz;
	RateDivider10Hz rd10hz (.CO(CLOCK_10Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_20Hz;
	RateDivider20Hz rd20hz (.CO(CLOCK_20Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_40Hz;
	RateDivider40Hz rd40hz (.CO(CLOCK_40Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_80Hz;
	RateDivider80Hz rd80hz (.CO(CLOCK_80Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire CLOCK_160Hz;
	RateDivider160Hz rd160hz (.CO(CLOCK_160Hz), .Clock(CLOCK_50), .Areset(RateDivreset));
	
	wire [7:0] ctrl;
	rand_module rm (.Rreset(Rreset), .CLOCK_50(CLOCK_50), .CLOCK_1Hz(CLOCK_1Hz), .Rload_lfsr(Rload_lfsr), .Rshift(Rshift), .Rspeed(Rspeed), .ctrl(ctrl));

	wire [7:0] mole_hit;
	MoleWhackFSM8Way mwfsm8w (.reset(Wreset), .CLOCK_50(CLOCK_40Hz), .SW(SW) ,.mole_hit(mole_hit));
	
	reg [2:0] level;
	always @(posedge incr_level, posedge reset_level) begin 
		if(reset_level)
			level <= 3'b0;
		else 
			level <= level + 1'b1;
	end
	
	wire clock_wait;
	assign clock_wait = (level == 3'b000) ? CLOCK_2Hz : ((level == 3'b001) ? CLOCK_4Hz : ((level == 3'b010) ? CLOCK_8Hz : ((level == 3'b011) ? CLOCK_16Hz : ((level == 3'b100) ? CLOCK_50 : 1'b1))));
	
	wire [39:0] Mheight;
	wire [15:0] totalRise;
	wire [15:0] totalScore;
	CompleteCount cc (.reset_scores(CReset_score), .reset_moles(CReset_moles), .clock(CLOCK_50), .clock_wait(clock_wait), .clockrL(CLOCK_40Hz), .control((Cenable_ctrl == 1'b0) ? 8'b0 :ctrl), .mole_hit(mole_hit), .Mheight(Mheight), .totalScore(totalScore), .totalRise(totalRise));
	
	
	wire plot_mas;
	wire [7:0] x_mas;
	wire [6:0] y_mas;
	wire [2:0] col_mas;
	MoleAndScore mas(.x(x_mas), .y(y_mas), .col(col_mas), .plot(plot_mas), .molePositions(Mheight), .total(totalRise), .score(totalScore), .CLOCK_40(CLOCK_40Hz), .CLOCK_50(CLOCK_50), .reset(Gmas_reset));
	
	wire plot_lev;
	wire [7:0] x_lev;
	wire [6:0] y_lev;
	wire [2:0] col_lev;
	LevelVGADisplay lvd (.x(x_lev), .y(y_lev), .col(col_lev), .plot(plot_lev), .level({1'b0, level}), .CLOCK_50(CLOCK_50), .reset(Glev_reset));
	
	//TODO: Add clear module
	always @(*) begin 
		if(GVideo_source == 2'b00) begin 
			x = x_mas;
			y = y_mas;
			plot = plot_mas;
			col = col_mas;
		end
		else if (GVideo_source == 2'b01) begin 
			x = x_lev;
			y = y_lev;
			plot = plot_lev;
			col = col_lev;
		end 
		else begin 
			x = 8'b0;
			y = 7'b0;
			plot = 1'b0;
			col = 3'b100;
		end
	end
	
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
	
	MoleWhackFSM mwf1 (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[0]) ,.mole_hit(mole_hit[0]));
	MoleWhackFSM mwf2 (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[1]) ,.mole_hit(mole_hit[1]));
	MoleWhackFSM mwf3 (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[2]) ,.mole_hit(mole_hit[2]));
	MoleWhackFSM mwf4 (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[3]) ,.mole_hit(mole_hit[3]));
	MoleWhackFSM mwf5 (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[4]) ,.mole_hit(mole_hit[4]));
	MoleWhackFSM mwf6 (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[5]) ,.mole_hit(mole_hit[5]));
	MoleWhackFSM mwf7 (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[6]) ,.mole_hit(mole_hit[6]));
	MoleWhackFSM mwf8 (.reset(reset), .CLOCK_50(CLOCK_50), .switch(SW[7]) ,.mole_hit(mole_hit[7]));
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
		else if({thousands, hundreds, tens, ones} == 16'b1001_1001_1001_1001)
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

//**************************************
//GRAPHICS MODULES AND CORRESP RAM
//
//
//**************************************

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
//Active high reset
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


module LevelVGADisplay (x, y, col, plot, reset, level, CLOCK_50);
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] col;
	output reg plot;
	
	input [3:0] level;
	input reset; //ACTIVE LOW reset
	input CLOCK_50;
	
	reg [1:0] curr_obj;
	reg [1:0] prev_curr_obj;
	
	reg [5:0] levx;
	reg [3:0] levy;
	reg [5:0] prev_levx;
	reg [3:0] prev_levy;
	reg [8:0] addresslev;
	
	reg [2:0] digX;
	reg [2:0] pastdigX;
	reg [3:0] digY;
	reg [3:0] pastdigY;
	reg [5:0] addressdig;
	
	wire [2:0] delayedlev;
	
	wire [2:0] delayeddig;
	
	always @(*) begin 
		if (prev_curr_obj == 2'b10)
			begin
			x = 8'd57 + prev_levx;
			y = 7'd20 + prev_levy;
			col = delayedlev;
			end
		else if (prev_curr_obj == 2'b01)
			begin 
			x = 8'd97 + pastdigX;
			y = 7'd20 + pastdigY;
			col = delayeddig;
			end
		else
			begin
			x = 8'b0;
			y = 7'b0;
			col = 3'b0;
			end
	end
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b0)  
			curr_obj <= 2'b0;
		else if (curr_obj == 2'b0)
			curr_obj <= curr_obj + 1'b1;
		else if (curr_obj == 2'b01 && digX == 3'd5 && digY == 4'd9) 
			curr_obj <= curr_obj + 1'b1;
		else if (curr_obj == 2'b10 && levx == 6'd37 && levy == 4'd9)
			curr_obj <= 2'b0;
	end
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b0 || plot == 1'b0)
			prev_curr_obj <= 2'b0;
		else
			prev_curr_obj <= curr_obj;
	end
	
	always @(posedge CLOCK_50) begin
		plot <= reset;
	end 
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b0 || plot == 1'b0 || curr_obj != 2'b10)
			begin
			levx <= 6'b0;
			prev_levx <= 6'b0;
			
			levy <= 4'b0;
			prev_levy <= 4'b0;
			
			addresslev <= 9'b0;
			end
		else if (plot == 1'b1 && levx == 6'd37 && levy == 4'd9)
			begin
			prev_levx <= levx;
			levx <= 6'b0; //reset at max
			
			prev_levy <= levy;
			levy <= 4'b0; //reset at max
			
			addresslev <= 9'b0; //reset at max
			end
		else if (plot == 1'b1 && levx == 6'd37)
			begin
			prev_levx <= levx;
			levx <= 6'b0; //reset at max
			
			prev_levy <= levy;
			levy <= levy + 1'b1;
			
			addresslev <= addresslev + 1'b1;
			end
		else if (plot == 1'b1)
			begin
			prev_levx <= levx;
			levx <= levx + 1'b1; //incr if curr_obj is a digit
			
			prev_levy <= levy;
			
			addresslev <= addresslev + 1'b1;
			end
	end
	
	
	LevelRam lr (.address(addresslev),.clock(CLOCK_50),.data(3'b0),.wren(1'b0),.q(delayedlev));
	
	always @(posedge CLOCK_50) begin
		if(reset == 1'b0 || plot == 1'b0 || curr_obj != 2'b01)
			begin
			digX <= 3'b0;
			pastdigX <= 3'b0;
			
			digY <= 4'b0;
			pastdigY <= 4'b0;
			
			addressdig <= 6'b0;
			end
		else if (plot == 1'b1 && digX == 3'd5 && digY == 4'd9)
			begin
			pastdigX <= digX;
			digX <= 3'b0; //reset at max
			
			pastdigY <= digY;
			digY <= 4'b0; //reset at max
			
			addressdig <= 6'b0; //reset at max
			end
		else if (plot == 1'b1 && digX == 3'd5)
			begin
			pastdigX <= digX;
			digX <= 3'b0; //reset at max
			
			pastdigY <= digY;
			digY <= digY + 1'b1;
			
			addressdig <= addressdig + 1'b1;
			end
		else if (plot == 1'b1)
			begin
			pastdigX <= digX;
			digX <= digX + 1'b1; //incr if curr_obj is a digit
			
			pastdigY <= digY;
			
			addressdig <= addressdig + 1'b1;
			end
	end
	digit_info di (.digit(level), .address(addressdig), .clock(CLOCK_50), .q(delayeddig), .reset(~reset));
	endmodule

//***********************************
// RAM MODULES
//
//
//***********************************


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module LevelRam (
	address,
	clock,
	data,
	wren,
	q);

	input	[8:0]  address;
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
		altsyncram_component.init_file = "level.colour.mif",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 380,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 9,
		altsyncram_component.width_a = 3,
		altsyncram_component.width_byteena_a = 1;


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
