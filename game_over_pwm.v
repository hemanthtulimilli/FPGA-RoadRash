///////////////////////////////////////////
// Last Modified:	6-Jun-2015
// Description:
// ------------
// created by: Bala Prashanth Reddy Chappidi
//This module is created for the game over sound. 
//The system clock is taken as input and a pwm signal is generated as output. 
//The counter increments on respective sound cycles which is the core behind racing sound of bike depending on increase or decrease of speed.
//The flags audio and counter_2 are compared and set when the collision happens and sound is passed through pwm.
///////////////////////////////////////////

module game_over(clk, pwm);										  // game_over sound module
input 	clk;
output 	pwm;
 
reg 	[27:0] 	audio;                                            // signal used to define the count of the counter to produce pwm in steps to produce the game_over sound
reg 	pwm;  
reg 	[14:0] 	counter = 15'd0;                                  // counter to generate pwm
wire 	[6:0]	pwm_temp = (audio[25] ? audio[24:18] : ~audio[24:18])  // using the audio bits [24:18] to generate a ramp kind of signal to produce pwm 
wire 	[6:0] 	off = 7'b0;
reg  	[19:0]  counter_2 = 20'd0;                                // intermediate counter to count the number of sound cycles. Here in this case we restricted it to 8 continuous sound beeps and then stop.

always @(posedge clk) begin
 if((audio == 28'd0) && (counter_2 < 20'h00004))                  // comparing audio signal and counter_2-intermediate counter to restrict game over sound to 8 beeps.
    
	counter_2 <= counter_2 + 20'd1; 							  // incrementing the counter_2
	
 else
    
	counter_2 <= counter_2;
	audio <= audio-1;
 end
 
always @(posedge clk) begin
	if(counter==0) begin                                           // This is done to produce the actual pwm
	
		counter <= clk_divider;                                    // clk_divider is to set the count of the counter(main counter)
	end
	else	
		counter <= counter-1;       
	end
	
always @(posedge clk) begin 
	if(counter_2 < 20'h00004) begin                                // comparing the intermediate counter to make 8 continuous gameover sound cycles.
		if(counter==0) 
		pwm <= ~pwm;                                               // this generates the needed pwm signals.
		end
	else begin
		pwm <= 1'b0;                                                       
	end
 end
endmodule