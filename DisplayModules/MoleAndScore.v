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
		
	reg [4:0] counter;
		
	wire [39:0]  temp_val = {counter [4:0] , 35'b00010_00100_01000_10000_10011_10100_00100};
	wire slowed;
	
	always @(posedge slowed) begin
		if(resetn == 1'b0 || counter == 5'd20)
			counter <= 5'b0;
		else 
			counter <= counter + 1;
	end
	
	RateDivider rd40(.CO(slowed), .Clock(CLOCK_50), .Areset(resetn));
		
	MoleAndScore mas(.x(x), .y(y), .col(colour), .plot(writeEn), .molePositions(temp_val), .total(16'b0), .score(16'b0), .CLOCK_40(slowed), .CLOCK_50(CLOCK_50), .reset(~resetn));
	
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
	
	localparam  STOP_VAL = 5'b01001,
				TS = 5'b01000;
	
	reg [4:0] curr_obj; // 0 to STOP_VAL.
	reg [4:0] prev_curr_obj;
	reg [8:0] moleYX;
	reg [8:0] pastmoleYX;
	reg [4:0] currMoleShift;
	reg go;
	
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
		//later add cases for 01001 and higher
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
		else
			x = 8'b0;
	end
	
	always @(*) begin
		if(prev_curr_obj[4:3] == 2'b00)
				y [6:0]= 7'd100 + pastmoleYX[8:4];
		else if(prev_curr_obj[4:0] == TS)
			y = 7'd20 + pasttsY;
		else
			y [6:0]= 7'b0;
	end
	
	always @(*) begin
		if(prev_curr_obj[4:3] == 2'b00)
				col [2:0] = delayedMoleImage[2:0];
		else if(prev_curr_obj[4:0] == TS)
			col [2:0] = delayedTS[2:0];
		else
			col [2:0] = 3'b0;
	end

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