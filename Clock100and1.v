/****************************
*  Generate 100 Hz and 1 Hz *
*  clocks from CLOCK_50 of  *
*  DE0 board                *
*  11-25-12, P. Mathys      *
****************************/

module Clock100and1(ClkIn,En,En1,Clr_,Clk100,Clk1);
	input ClkIn;         // 50 MHz clock input
	input En;            // Enable clock generation
	input En1;           // Enable 1 Hz generation
	input Clr_;          // Clear all registers
	output Clk100;       // 100 Hz clock
	output Clk1;         // 1 Hz clock
	parameter N1 = 5;    // Prescaler, divide by 32
	wire [N1-1:0] QQ1;
	wire TCO1;           // Terminal count 1
	reg TCO1S;           // TCO1 synchronized
	parameter N2 = 14;   // Divide by 15625 counter
	parameter M2 = 15625;
	wire [N2-1:0] QQ2;
	wire CM2;            // M2-1 count detect
	reg CM2S;            // Synchronized CM2
	wire TCO2;
	parameter N3 = 7;    // Divide by 100 counter
	parameter M3 = 100;
	wire [N3-1:0] QQ3;
	wire CM3;            // M3-1 count detect
	reg CM3S;            // Synchronized CM3
	wire TCO3;
	
	TffCounter #(.N(N1)) div32(ClkIn,En,Clr_,1'b1,QQ1,TCO1);
	always @(negedge ClkIn)
		if (TCO1) TCO1S <= 1'b1;
		else TCO1S <= 1'b0;
	TffCounter #(.N(N2)) div15625(TCO1S,En,Clr_,~CM2,QQ2,TCO2);
	assign CM2 = (QQ2 == M2-1) ? 1'b1 : 1'b0;
	always @(negedge TCO1S)
		if (CM2) CM2S <= 1'b1;
		else CM2S <= 1'b0;
	assign Clk100 = CM2S;
	TffCounter #(.N(N3)) div100(Clk100,En&En1,Clr_,~CM3,QQ3,TCO3);
	assign CM3 = (QQ3 == M3-1) ? 1'b1: 1'b0;
	always @(negedge Clk100)
		if (CM3) CM3S <= 1'b1;
		else CM3S <= 1'b0;
	assign Clk1 = CM3S;
endmodule // Clock100and1

/***********************************
*  Positive edge-triggered N-bit   *
*  T flip-flop counter with        *
*  enable (En) input, asynchronous *
*  (Clr_) and synchronous (ClrS_)  *
*  clear, and terminal count       *
*  output (TCO).                   *
*  11-22-12, P. Mathys             *
***********************************/

module TffCounter(Clk,En,Clr_,ClrS_,QQ,TCO);
	parameter N = 4;   // Number of bits
	input Clk;         // Clock
	input En;          // Enable
	input Clr_;        // Asynchronous clear
	input ClrS_;       // Synchronous clear
	output [N-1:0] QQ; // Flip-flop state values
	output TCO;        // Terminal (all 1's) count output
	wire [N:0] TT;     // Flip-flop T values
	
	genvar i;
	assign TT[0] = En;
	generate
		for (i=0; i<N; i=i+1) begin: unit
			TffUnit FF(Clk,TT[i],Clr_,ClrS_,TT[i+1],QQ[i]);
		end
	endgenerate
	assign TCO = &QQ;
endmodule  // TffCounter

/**************************
*  T flip-flop with Clr_, *
*  synchronous ClrS_, and *
*  Tout = T&Q             *
*  11-22-12, P. Mathys    *
**************************/

module TffUnit(Clk,T,Clr_,ClrS_,Tout,Q);
	input Clk,T;  // Clock and T inputs
	input Clr_;   // Asynchronous clear
	input ClrS_;  // Synchronous clear
	output Tout;  // T output for next stage
	output reg Q;
	
	always @(posedge Clk, negedge Clr_)
		if (!Clr_) Q <= 1'b0;
		else if (!ClrS_) Q <= 1'b0;
		else Q <= Q&~T|~Q&T;
	assign Tout = T&Q;
endmodule  // TffUnit