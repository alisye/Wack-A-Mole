module testRL (reset, go, CLOCK_50, CLOCK_WAIT, CLOCK_RL);
	input reset, go, CLOCK_50, CLOCK_RL, CLOCK_WAIT;
	
	wire Mreset_height;
	wire Mreset_wait;
	wire Mheight_en;
	wire Mheight_incr;
	wire [2:0] Mwait;
	wire [4:0] Mheight;
	
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