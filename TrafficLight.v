/*
 * DE0 Assignment: Traffic Light
 * ECEN 2350
 * Ben Cavins (benjamin.cavins@colorado.edu)
 * 2013-04-15
 */
module TrafficLight(ClkIn, Resetn, Sensor, ssd0, ssd1, ssd2, ssd3);
	input ClkIn;   // 5GHz Clock
	input Resetn;  // Reset button
	input Sensor;  // Traffic Sensor for Farm Road
	output [6:0] ssd0, ssd1, ssd2, ssd3; // SSDs
	wire [1:0] HY; // Highway Light Value
	wire [1:0] FR; // Farm Road Light Value
	wire [7:0] c;  // Counter
	wire Clk100;   // 100Hz Clock
	wire Clk1;     // 1Hz Clock
	wire [2:0] state;      // Current State
	wire [3:0] dig0, dig1; // Timer Digits for SSDs
	reg [7:0] stateToSSD;  // Convert State for SSD
	
	// 1 Hz Clock
	Clock100and1 clk1hz (ClkIn, 1, 1, 1, Clk100, Clk1);
	
	// Traffic Light Finite State Machine
	traffic_light_fsm tlfsm (Clk1, Resetn, Sensor, c, HY, FR, state);
	
	// Convert Timer to BCD for SSD
	BtoBCD timer (c, dig1, dig0);
	
	// Set Up SSDs
	TLtoSSD(Clk1, HY, FR, ssd0);
	stateToSSD(state, ssd1);
	ssdd display2 (dig0, ssd2);
	ssdd display3 (dig1, ssd3);
endmodule

/*
 * Finite State Machine for traffic light
 */
module traffic_light_fsm(Clk, Reset, w, count, hy, fr, y);
	input Clk, Reset, w;
	output reg [1:0] hy, fr;
	output reg [2:0] y;
	output reg [7:0] count = 8'b0;
	reg [2:0] Y;
	reg [7:0] z;
	parameter [2:0] A=3'b000,B=3'b001,C=3'b010,D=3'b011,E=3'b100,F=3'b101;
	parameter [1:0] G=2'd0,Yw=2'd1,R=2'd2;
	
	// Define Next State
	always @(w, y) begin
		case (y)
			A: if(w) Y=B;
				else  Y=A;
			B: if(w) Y=C;
				else  Y=C;
			C: if(w) Y=D;
				else  Y=D;
			D: if(w) Y=F;
				else  Y=E;
			E: if(w) Y=A;
				else  Y=A;
			F: if(w) Y=E;
				else  Y=E;
			default: Y=3'bxxx;
		endcase
	end
	
	// Sequential Block
	always @(posedge Clk) begin
		count = count+1;  // Increment counter
		if (Reset == 0) begin
			y <= A;
			count = 0;
		end else if (count >= z) begin 
			y <= Y;
			count = 0;
		end
		if (y == F && w == 0) begin
			y <= Y;
			count = 0;
		end
	end
	
	// Define Output
	always @(y, w) begin
		case (y)
			A: begin
					z  = 1;
					hy = G;
					fr = R;
				end
			B: begin	
					z  = 30;
					hy = G;
					fr = R;
				end
			C: begin
					z  = 5;
					hy = Yw;
					fr = R;
				end
			D: begin
					z  = 5;
					hy = R;
					fr = G;
				end
			E: begin
					z = 5;
					hy = R;
					fr = Yw;
				end
			F: begin
					z  = 5;
					hy = R;
					fr = G;
				end
			default: begin
					z  = 8'bxxxxxxxx;
					hy = 2'bxx;
					fr = 2'bxx;
				end
		endcase
	end
endmodule

/*
 * Stupidly convert a binary number to a 2 digit BCD
 */
module BtoBCD(n, d1, d0);
	input [7:0] n;
	output [4:0] d0, d1;
	
	assign d1 = (n/10);
	assign d0 = (n-(10*d1));
endmodule

/*
 * Convert traffic light code (Red, Green, Yellow) to
 * an SSD
 */
module TLtoSSD(ClkIn, hw, fr, display);
	input ClkIn;
	input [1:0] hw, fr;
	output reg [6:0] display = 7'b1111111;
	reg t = 0;
	parameter [1:0] Green=2'b00,Yellow=2'b01,Red=2'b10;
	
	always @(posedge ClkIn) begin
		t = ~t;
	end
	
	always @(hw, fr, ClkIn) begin

		// Highway Lights
		if (hw == Green) begin
			display[1] = 1'b1;
			display[2] = 1'b1;
			display[4] = 1'b1;
			display[5] = 1'b1;
		end else if (hw == Yellow) begin
			display[1] = (t) ? 1'b1 : 1'b0;
			display[2] = (t) ? 1'b1 : 1'b0;
			display[4] = (t) ? 1'b1 : 1'b0;
			display[5] = (t) ? 1'b1 : 1'b0;
		end else begin
			display[1] = 1'b0;
			display[2] = 1'b0;
			display[4] = 1'b0;
			display[5] = 1'b0;
		end
		
		// Farm Road Lights
		if (fr == Green) begin
			display[0] = 1'b1;
			display[3] = 1'b1;
		end else if (fr == Yellow) begin
			display[0] = (t) ? 1'b1 : 1'b0;
			display[3] = (t) ? 1'b1 : 1'b0;
		end else begin
			display[0] = 1'b0;
			display[3] = 1'b0;
		end
		
	end
endmodule

/*
 * Convert state for SSD
 */
module stateToSSD(state, ssd);
	input [2:0] state;
	output [6:0] ssd;
	reg [3:0] v;
	
	always @(state) begin
		if (state == 3'b000) v = 4'hA;
		else if (state == 3'b001) v = 4'hB;
		else if (state == 3'b010) v = 4'hC;
		else if (state == 3'b011) v = 4'hD;
		else if (state == 3'b100) v = 4'hE;
		else if (state == 3'b101) v = 4'hF;
		else v = 4'h0;
	end
	
	ssdd toSSD (v, ssd);
endmodule
