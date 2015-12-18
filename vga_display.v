`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Boston University
// Engineer: Zafar M. Takhirov
// 
// Create Date:    12:59:40 04/12/2011 
// Design Name: EC311 Support Files
// Module Name:    vga_display 
// Project Name: Lab5 / Lab6 / Project
// Target Devices: xc6slx16-3csg324
// Tool versions: XILINX ISE 13.3
// Description: 
//
// Dependencies: vga_controller_640_60
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga_display(rst, clk, R, G, B, HS, VS,up,down,up2,down2,dispout,AN,newgame);
	input rst;	// global reset
	input clk;	// 100MHz clk
	input newgame;
	// color outputs to show on display (current pixel)
	output reg [2:0] R, G;
	output reg [1:0] B;
	output reg [7:0] dispout;
	output reg [3:0] AN;
	reg [2:0] R1,G1;
	reg [1:0] B1;
	wire [2:0] R2,G2;
	wire [1:0] B2;
	reg select;
		// memory interface:
	wire [14:0] addra;
	wire [7:0] douta;
	wire figureGM;
	// Synchronization signals
	output HS;
	output VS;
	
	// controls:
	wire [10:0] hcount, vcount;	// coordinates for the current pixel
	wire blank;	// signal to indicate the current coordinate is blank
	wire figure;	// the figure you want to display
	wire figure2;
	wire ball;
	
	/////////////////////////////////////////////////////
	// Begin clock division
	parameter N = 2;	// parameter for clock division
	reg clk_25Mhz;
	reg [N-1:0] count;
	always @ (posedge clk) begin
		count <= count + 1'b1;
		clk_25Mhz <= count[N-1];
	end
	// End clock division
	/////////////////////////////////////////////////////
	
	
	
	/////////////////////////////////////////
	// State machine parameters	
	parameter S_IDLE = 0;	// 0000 - no button pushed
	parameter S_UP = 1;		// 0001 - the first button pushed	
	parameter S_DOWN = 2;	// 0010 - the second button pushed
	parameter S_UP2 = 4;		
	parameter S_DOWN2 = 8;	
	parameter S_BUP = 5;
	parameter S_BDOWN =10;
	parameter S_1UP2DOWN = 9;
	parameter S_2UP1DOWN = 6;
	
	parameter S_BALLIDLE = 0;
	parameter S_BALLUPRIGHT = 2;
	parameter S_BALLUPLEFT = 1;
	parameter S_BALLDOWNLEFT = 3;
	parameter S_BALLDOWNRIGHT = 4;
	parameter S_P1WINS = 5;
	parameter S_P2WINS = 6;

	reg [2:0] ballstate, next_ballstate;
	reg [3:0] state, next_state;
	reg [4:0] score1,score2;
	reg led_count;
	////////////////////////////////////////	

	input up, down, up2, down2; 	// 1 bit inputs	
	reg [10:0] ballx, y, bally, y2,sdirect;				//currentposition variables
	reg slow_clk,pdl_clk;		// clock for position update,	
									// if it's too fast, every push
									// of a button willmake your object fly away.

	initial begin					// initial position of the box	
		ballx = 300; y=20; bally=200; y2=20;score1 = 0;score2=0; sdirect=0;
		select=0;
	end	

	////////////////////////////////////////////	
	// slow clock for position update - optional
	reg [19:0] slow_count;	
	always @ (posedge clk)begin
		slow_count = slow_count + 1'b1;	
		slow_clk = slow_count[19];
	end	
	
	reg [20:0] pdl_count;	
	always @ (posedge clk)begin
		pdl_count = pdl_count + 1'b1;	
		pdl_clk = pdl_count[20];
	end	
	/////////////////////////////////////////

	always @ (posedge slow_clk) begin
		led_count=led_count + 1'b1;
		case(led_count)
			1'b1 :begin
					AN=4'b0111;
						case(score1)	
							0:	dispout= 8'b11000000;
							2: dispout= 8'b11111001;
							4: dispout= 8'b10100100;
							6: dispout= 8'b10110000;
							8: dispout= 8'b10011001;
							10: dispout= 8'b10010010;
							12: dispout= 8'b10000010;
							14: dispout= 8'b11111000;
						endcase
					end
			1'b0 :begin
					AN=4'b1110;
						case(score2)	
							0:	dispout= 8'b11000000;
							2: dispout= 8'b11111001;
							4: dispout= 8'b10100100;
							6: dispout= 8'b10110000;
							8: dispout= 8'b10011001;
							10: dispout= 8'b10010010;
							12: dispout= 8'b10000010;
							14: dispout= 8'b11111000;
						endcase
					end
		endcase
	end
	///////////////////////////////////////////
	// State Machine	
	always @ (posedge pdl_clk)begin
		state = next_state;	
	end

	always @ (posedge pdl_clk) begin	
		case (state)
			S_IDLE: next_state = {down2,up2,down,up}; // if input is 0000
			S_UP: begin	// if input is 0001
				if ((y-5) >= 1 )
					begin
					y = y - 5;
					end
				next_state = {down2,up2,down,up};
			end	
			S_DOWN: begin // if input is 0010
				if ((y+5) < 415 )
					begin
					y = y + 5;
					end
				next_state = {down2,up2,down,up};
			end
			S_UP2: begin	// if input is 0001
				if ((y2-5) >= 1 )
					begin
					y2 = y2 - 5;
					end	
				next_state = {down2,up2,down,up};
			end	
			S_DOWN2: begin // if input is 0010
				if ((y2+5) < 415 )
					begin
					y2 = y2 + 5;
					end
				next_state = {down2,up2,down,up};
			end
			S_BUP: begin // if input is 0010
				if ((y2-5) >= 1 )
					begin
					y2 = y2 - 5;
					end	
				if ((y-5) >= 1 )
					begin
					y = y - 5;
					end	
				next_state = {down2,up2,down,up};
			end
			S_BDOWN: begin // if input is 0010
				if ((y2+5) < 415 )
					begin
					y2 = y2 + 5;
					end
				if ((y+5) < 415 )
					begin
					y = y + 5;
					end
				next_state = {down2,up2,down,up};
			end
			S_1UP2DOWN: begin // if input is 0010
				if ((y2+5) < 415 )
					begin
					y2 = y2 + 5;
					end
				if ((y-5) >= 1 )
					begin
					y = y - 5;
					end	
				next_state = {down2,up2,down,up};
			end
			S_2UP1DOWN: begin // if input is 0010
				if ((y2-5) >= 1 )
					begin
					y2 = y2 - 5;
					end	
				if ((y+5) < 415 )
					begin
					y = y + 5;
					end
				next_state = {down2,up2,down,up};
			end
			//complete state machine
		endcase
	end
always @ (posedge clk_25Mhz) begin
   if( select == 0) begin
       R=R1;
		 G=G1;
		 B=B1;
		end
   else if( select == 1)begin
      R=R2;
	   G=G2;
	   B=B2;
	  end
end

vga_bsprite sprites_mem(
		.x0(50+100), 
		.y0(50+100),
		.x1(393+100),
		.y1(97+100),
		.hc(hcount), 
		.vc(vcount), 
		.mem_value(douta), 
		.rom_addr(addra), 
		.R(R2), 
		.G(G2), 
		.B(B2), 
		.blank(blank)
	);

	
	always @ (posedge slow_clk)begin
		ballstate = next_ballstate;	
	end

	always @ (posedge slow_clk) begin	
		case (ballstate)
			S_IDLE:begin
				if (sdirect==0 || sdirect==4 || sdirect==12 || sdirect==24 ) 
					begin
					next_ballstate = 1; // if input is 0000
					end
				else if (sdirect==2 || sdirect==6 || sdirect==14 )
					begin
					next_ballstate = 2; // if input is 0000
					end
				else if (sdirect==10 || sdirect==16 || sdirect==20 )
					begin
					next_ballstate = 3; // if input is 0000
					end
				else if (sdirect==8 || sdirect==18 || sdirect==22  )
					begin
					next_ballstate = 4;
					end
				else 
					begin
					next_ballstate = 1; // if input is 0000
					end
			end
			S_BALLUPRIGHT:begin
				if (((ballx+1) <= 610) && ((bally-1) >= 1 ) ) //up
					begin
					ballx = ballx + 1;
					bally = bally - 1;
					next_ballstate = 2;
					end
				else 
					begin
					if ((ballx+1) > 610)
							begin
							if ((bally >=top_paddle2) && (bally <= bot_paddle2 ))
								begin
								next_ballstate=1;
								end
							else
								begin
								sdirect=sdirect+1;
								next_ballstate=5;
								end
							 //game over, player 1 wins
							end
					else if ((bally-1) < 1 )
						begin
						next_ballstate=4;
						end
					end
			end
			S_BALLUPLEFT:begin
				if (((ballx-1) >= 20)&&((bally-1) >= 1)) //up
					begin
					ballx = ballx -1;
					bally = bally -1;
					next_ballstate = 1;
					end
				else 
					begin
						if ((ballx-1) < 20 ) 
							begin
								if ((bally >= top_paddle1) && (bally <=bot_paddle1))
									begin
										next_ballstate=2;
									end
								else
									begin
										sdirect=sdirect+1;
										next_ballstate=6;//game over, player 2 wins
									end
							end
						else
							begin
								next_ballstate=3;
							end
					end

			end
			S_BALLDOWNLEFT:begin
				if (((ballx-1) >= 20 ) && ((bally+1) <= 470 )) //up
					begin
					ballx = ballx -1;
					bally = bally +1;
					next_ballstate = 3;
					end
				else 
					begin
						if ((ballx-1) < 20 ) 
							begin
								if ((bally >= top_paddle1) && (bally <=bot_paddle1))
									begin
										next_ballstate=4;
									end
								else
									begin
										sdirect=sdirect+1;
										next_ballstate=6;//game over, player 2 wins
									end
							end
						else
							begin
								next_ballstate=1;
							end
					end
			end
			S_BALLDOWNRIGHT:begin
				if (((ballx+1) <= 610 )&&((bally+1) <= 470 ))//up
					begin
					bally = bally +1;
					ballx = ballx +1;
					next_ballstate = 4;
					end
				else 
					begin
						if ((ballx+1) > 610 )
							begin
								if ((bally >= top_paddle2) && (bally <= bot_paddle2 ))
									begin
										next_ballstate=3;
									end
								else
									begin
										sdirect=sdirect+1;
										next_ballstate=5;//game over, player 1 wins
									end
							end
						else if ((bally+1) > 470 )
							begin 
								next_ballstate = 2;
							end
					end
			end
			S_P1WINS:begin		
				if (score1 <14) begin
					score1=score1+1;
					ballx = 300;
					bally = 200;
					next_ballstate=0;
				end
				if (score1==14 && !(newgame)) begin
					select=1;
					next_ballstate =5;
				end
				if (score1==14 &&(newgame)) begin
					score1=0;
					score2=0;
					sdirect=0;
					select=0;
					ballx = 300;
					bally = 200;
					next_ballstate = 0;
				end
			
			end
			S_P2WINS:begin
				if (score2 <14) begin
					score2=score2+1;
					ballx = 300;
					bally = 200;
					next_ballstate=0;
				end
				if (score2==14 && !(newgame)) begin
					select= 1 ;
					next_ballstate = 6;
				end
				if (score2==14 &&(newgame)) begin
					score1=0;
					score2=0;
					sdirect=0;
					select=0;
					ballx = 300;
					bally = 200;
					next_ballstate = 0;
				end
			end
			//complete state machine
		endcase
	end
	
	// Call driver
	vga_controller_640_60 vc(
		.rst(rst), 
		.pixel_clk(clk_25Mhz), 
		.HS(HS), 
		.VS(VS), 
		.hcounter(hcount), 
		.vcounter(vcount), 
		.blank(blank));
	

	game_over_mem memory_1 (
		.clka(clk_25Mhz), // input clka
		.addra(addra), // input [14 : 0] addra
		.douta(douta) // output [7 : 0] douta
	);
	
	// create a box:
	reg [10:0] top_paddle1,bot_paddle1,top_paddle2,bot_paddle2;
	initial begin
		top_paddle1=y; bot_paddle1=60+y; top_paddle2=y2; bot_paddle2=60+y2;
	end
	
	assign figure = ~blank & (hcount >= 15 & hcount <= 20 & vcount >= top_paddle1 & vcount <= bot_paddle1);
	assign figure2 = ~blank & (hcount >= 610 & hcount <= 615 & vcount >= top_paddle2 & vcount <= bot_paddle2);
	assign ball = ~blank & (hcount >= ballx & hcount <= 5+ballx & vcount >= bally & vcount <= 5+bally);


	// send colors:
	always @ (posedge clk) begin
		if (figure) begin	// if you are within the valid region
			R1[0] = 0;
			G1[0] = 1;
			B1[0] = 0;
		end
		else begin	// if you are outside the valid region
			R1[0] = 0;
			G1[0] = 0;
			B1[0] = 0;
		end
	end
	
	always @ (posedge clk) begin
		if (figure2) begin	// if you are within the valid region
			R1[1] = 0;
			G1[1] = 0;
			B1[1] = 1;
		end
		else begin	// if you are outside the valid region
			R1[1] = 0;
			G1[1] = 0;
			B1[1] = 0;
		end
	end
	
	always @ (posedge clk) begin
		if (ball) begin	// if you are within the valid region
			R1[2] = 1;
			G1[2] =0;
		end
		else begin	// if you are outside the valid region
			R1[2] = 0;
			G1[2] = 0;
		end
	end



endmodule


