///////////////////////////////////////////
// Last Modified:	6-Jun-2015
// Description:
// ------------
// created by: Bala Prashanth Reddy Chappidi
//
//This module generates the pwm signal for the sound generated from the game_over_sound module. 
//if the value of duty cycle is anything but one,
//the pwm_audio goes to the next condition which is either comparing with the value of counter and sets to 0 or 1.
///////////////////////////////////////////


module pwm_audio											// pwm_audio module 
#(  parameter integer   CLK_FREQUENCY_HZ        = 100000000,// parameter values set 
	parameter integer   OFFSET_MULT             = 30,
	parameter integer   OFFSET_ADD              = 400,
	parameter integer 	CNTR_WIDTH 	    		= 32,
	parameter DUTY_CYCLE_WIDTH                  = 8			
	)
 
    (input         					clk,				 	// inputs and outputs from module
	input                           reset,
	input [7:0]                     speed,
	input [DUTY_CYCLE_WIDTH - 1:0]	duty_cycle,
	output	reg			pwm_audio_out
 );

   wire [7:0] speed_freq;
   assign speed_freq = (speed*OFFSET_MULT) + OFFSET_ADD; 	// using the speed form the speed module to define the frequency at which the bike acceleration should be produced.
   
     reg            [DUTY_CYCLE_WIDTH-1:0]  counter;
     reg			[CNTR_WIDTH-1:0]	clk_cnt; 			// count to implement something similar to clock counter
   	 wire	        [CNTR_WIDTH-1:0]	top_cnt = ((CLK_FREQUENCY_HZ / speed_freq ) - 1); // top_count to define the frequency
	 reg			tickhz;	

   // Block to implement the clk_divider 
	always @(posedge clk) begin
            if (reset) begin
                clk_cnt <= {CNTR_WIDTH{1'b0}};   			// setting the counter to zero upon reset 
            end 
            else if (clk_cnt >= top_cnt) begin   			// setting the tickhz to specify the frequency of pwm signal
                tickhz <= 1'b1;
                clk_cnt <= {CNTR_WIDTH{1'b0}};  
            end
            else begin
                clk_cnt <= clk_cnt + 1'b1;       			// else condition which increments clk_cnt and tickhz
                tickhz <= 1'b0;
            end
        end
   // Actual PWM generation block
    always @(posedge clk) begin
	if (reset) begin										// on every posedge clk the tickhz condition is checked and counter, pwm_audio_out are passed.
		pwm_audio_out 	<= 1'b0;
		counter	        <= 0;
	end
	else if (tickhz)  begin
		counter <= counter + 1;
		pwm_audio_out <= (duty_cycle) ? ((counter <= duty_cycle) ? 1'b1 : 1'b0) : 1'b0; // pwm generation involving conditional statements which counter values and duty_cycle values are checked.
	end
end

endmodule