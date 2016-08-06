`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////
// Project Name: RoadRash
// Engineer: Venkata Hemanth Tulimilli
// 
// Create Date: 05/29/2015 05:20:22 AM
// Module Name: final_main
// Target Devices: Nexys4DDR
// Description: This module acts as a game controller module which gives out position 
// of the image as well as which image to display on the screen
// for all the layers of display 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// This file is the controller for both icon module as well as  BCD module
//////////////////////////////////////////////////////////////////////////////////////


module final_main(
    input clk, reset,
    input [5:0] pBtns,
    output  reg [9:0]	bike_col_position,
	output	reg	[9:0]	left_car_row, left_car_column, right_car_row, right_car_column, middle_car_row, middle_car_column,
	output	reg	[2:0]	left_car_icon_num, right_car_icon_num, middle_car_icon_num, background_num,
	output  reg [15:0]  leds
    );

	// bike Local parameters
	localparam  DIST_MAX            = 16'd30000;
	localparam  BIKE_INIT_ROW       = 10'd485;
	localparam  BIKE_INIT_COL       = 10'd454;
	localparam  BIKE_MAX_COL        = 10'd908;
	localparam  BIKE_MIN_COL        = 10'd0;
	localparam  BIKE_COL_PIXELS     = 10'd116;
	localparam  BIKE_COL_CHANGE     = 10'd8;
	
	// general car local parameters
	localparam      COLUMN_MIN                      = 10'd0;
	localparam      COLUMN_MAX                      = 10'd1023;
	
	// left car local parameters
	localparam		LEFT_CAR_POSITION_2				= 10'd400;
	localparam		LEFT_CAR_POSITION_3				= 10'd415;
	localparam		LEFT_CAR_POSITION_4				= 10'd430;
	localparam		LEFT_CAR_POSITION_5				= 10'd470;
	localparam		LEFT_CAR_POSITION_6				= 10'd512;
	localparam		LEFT_CAR_ROW_INIT				= 10'd400;
	localparam		LEFT_CAR_COL_INIT				= 10'd500;
	localparam		LEFT_CAR_POSITION_MAX   		= 10'd768;
	
	// right car local parameters// need to calculate
	localparam		RIGHT_CAR_POSITION_2			= 10'd400;
	localparam		RIGHT_CAR_POSITION_3			= 10'd415;
	localparam		RIGHT_CAR_POSITION_4			= 10'd430;
	localparam		RIGHT_CAR_POSITION_5			= 10'd470;
	localparam		RIGHT_CAR_POSITION_6			= 10'd512;
	localparam		RIGHT_CAR_ROW_INIT				= 10'd400;
	localparam		RIGHT_CAR_COL_INIT				= 10'd524;
	
	// middle car local parameters										// need to calculate
	localparam		MIDDLE_CAR_POSITION_2			= 10'd400;
	localparam		MIDDLE_CAR_POSITION_3			= 10'd415;
	localparam		MIDDLE_CAR_POSITION_4			= 10'd430;
	localparam		MIDDLE_CAR_POSITION_5			= 10'd470;
	localparam		MIDDLE_CAR_POSITION_6			= 10'd512;
	localparam		MIDDLE_CAR_COL_POSITION_2		= 10'd495;
	localparam		MIDDLE_CAR_COL_POSITION_3		= 10'd495;
	localparam		MIDDLE_CAR_COL_POSITION_4		= 10'd479;
	localparam		MIDDLE_CAR_COL_POSITION_5		= 10'd383;
	localparam		MIDDLE_CAR_COL_POSITION_6		= 10'd383;
	localparam		MIDDLE_CAR_ROW_INIT				= 10'd400;
	localparam		MIDDLE_CAR_COL_INIT				= 10'd495;
	localparam		MIDDLE_CAR_ROW_MAX				= 10'd512;

	// clock divider parameters
    localparam          ONE_BIT_HIGH   = 1'b1;
    localparam          ONE_BIT_LOW    = 1'b0;
	localparam			CLK_FREQUENCY_HZ		= 100000000; 
	localparam			UPDATE_FREQUENCY_1HZ	= 1;
	localparam			UPDATE_FREQUENCY_5HZ	= 5;
	localparam			UPDATE_FREQUENCY_10HZ	= 10;
    localparam          UPDATE_FREQUENCY_20HZ   = 20;
    localparam          UPDATE_FREQUENCY_40HZ   = 40;
	localparam			UPDATE_FREQUENCY_50HZ	= 50;
	localparam		 	CNTR_WIDTH 				= 32;
	localparam			COUNT_1_3HZ				= 3;

	// clock divider 
	reg			[CNTR_WIDTH-1:0]	clk_cnt_5hz, clk_cnt_10hz, clk_cnt_20hz, clk_cnt_40hz, clk_cnt_50hz, clk_cnt_1hz;
	reg			[7:0]				clk_cnt_1_3hz;
	wire		[CNTR_WIDTH-1:0]	top_cnt_1hz = ((CLK_FREQUENCY_HZ / UPDATE_FREQUENCY_1HZ) - 1);
    wire        [CNTR_WIDTH-1:0]    top_cnt_5hz = ((CLK_FREQUENCY_HZ / UPDATE_FREQUENCY_5HZ) - 1);
	wire		[CNTR_WIDTH-1:0]	top_cnt_10hz = ((CLK_FREQUENCY_HZ / UPDATE_FREQUENCY_10HZ) - 1);
    wire        [CNTR_WIDTH-1:0]    top_cnt_20hz = ((CLK_FREQUENCY_HZ / UPDATE_FREQUENCY_20HZ) - 1);
    wire        [CNTR_WIDTH-1:0]    top_cnt_40hz = ((CLK_FREQUENCY_HZ / UPDATE_FREQUENCY_40HZ) - 1);
    wire        [CNTR_WIDTH-1:0]    top_cnt_50hz = ((CLK_FREQUENCY_HZ / UPDATE_FREQUENCY_50HZ) - 1);
	reg								tick1hz, tick5hz, tick10hz, tick20hz, tick40hz, tick50hz, tick_1_3hz;	    // update clock enable for 1Hz, 5Hz, 10Hz		

	// Local registers
	reg				left_car_display_flag, right_car_display_flag, middle_car_display_flag;
	reg        		obstacle_flag;
	reg     [7:0]   acceleration;
	reg     [7:0]   speed;
	reg             acceleration_flag, deceleration_flag;  
	reg     [15:0]  distance;

	// generate 1Hz clock enable and 1/3 Hz clock enable and creating different obstacle combinations
	// obstacles are created based on adding 7 for a 4 bit register
	// every 3 seconds to cover all the possible numbers of 4 bit number and create different order of obstacles
	always @(posedge clk) begin
		if (reset) begin
			clk_cnt_1hz <= {CNTR_WIDTH{1'b0}};
            tick_1_3hz <= 1'b0;
            clk_cnt_1_3hz <= 2'd0;
            count_init <= COUNT_INIT;
            obstacle_flag <= 4'd2;
            left_obstacle_flag <= 1'b0;
            right_obstacle_flag <= 1'b0;
            middle_obstacle_flag <= 1'b0;
		end
		else if (clk_cnt_1hz == top_cnt_1hz) begin
		    tick1hz <= 1'b1;
    	   if (clk_cnt_1_3hz == COUNT_1_3HZ) begin
                tick_1_3hz <= 1'b1;
                clk_cnt_1_3hz <= 2'd0;
                if(count_init == 3'd0) begin
                    obstacle_flag <= obstacle_flag + 4'd7;					// adding 7 to 4 bit register to create different obstacle order
                    if (obstacle_flag[3:1] == 3'b111) begin					// separating obstacle bits to left, right and middle obstacle flags
                        left_obstacle_flag <= 1'b0;							// if all three flags are set, make it no obstacle zone
                        right_obstacle_flag <= 1'b0;
                        middle_obstacle_flag <= 1'b0;
                    end
                    else begin
                        left_obstacle_flag <= obstacle_flag[3];
                        right_obstacle_flag <= obstacle_flag[2];
                        middle_obstacle_flag <= obstacle_flag[1];
                    end                    
                end
                else begin
                    obstacle_flag <= obstacle_flag;
                    count_init <= count_init - 3'd1;
                    left_obstacle_flag <= 1'b0;
                    right_obstacle_flag <= 1'b0;
                    middle_obstacle_flag <= 1'b0;
                end
            end
            else begin
                clk_cnt_1_3hz <= clk_cnt_1_3hz + 2'd1;
               // left_car_display_flag <= 1'b0;
                tick_1_3hz <= 1'b0;
                left_obstacle_flag <= 1'b0;
                right_obstacle_flag <= 1'b0;
                middle_obstacle_flag <= 1'b0;
            end
		    clk_cnt_1hz <= {CNTR_WIDTH{1'b0}};
		end
		else begin
		    clk_cnt_1hz <= clk_cnt_1hz + 1'b1;
		    tick1hz <= 1'b0;
		end
	end // update clock enable

	// generate 5Hz clock enable
	always @(posedge clk) begin
		if (reset) begin
			clk_cnt_5hz <= {CNTR_WIDTH{1'b0}};
		end
		else if (clk_cnt_5hz == top_cnt_5hz) begin
		    tick5hz <= 1'b1;
		    clk_cnt_5hz <= {CNTR_WIDTH{1'b0}};
		end
		else begin
		    clk_cnt_5hz <= clk_cnt_5hz + 1'b1;
		    tick5hz <= 1'b0;
		end
	end // update clock enable
	
    // generate 10Hz clock enable
    always @(posedge clk) begin
        if (reset) begin
            clk_cnt_10hz <= {CNTR_WIDTH{1'b0}};
        end
        else if (clk_cnt_10hz == top_cnt_10hz) begin
            tick10hz <= 1'b1;
            clk_cnt_10hz <= {CNTR_WIDTH{1'b0}};
        end
        else begin
            clk_cnt_10hz <= clk_cnt_10hz + 1'b1;
            tick10hz <= 1'b0;
        end
    end // update clock enable
	
    // generate 20Hz clock enable
    always @(posedge clk) begin
        if (reset) begin
            clk_cnt_20hz <= {CNTR_WIDTH{1'b0}};
        end
        else if (clk_cnt_20hz == top_cnt_20hz) begin
            tick20hz <= 1'b1;
            clk_cnt_20hz <= {CNTR_WIDTH{1'b0}};
        end
        else begin
            clk_cnt_20hz <= clk_cnt_20hz + 1'b1;
            tick20hz <= 1'b0;
        end
    end // update clock enable
	
    // generate 40Hz clock enable
    always @(posedge clk) begin
        if (reset) begin
            clk_cnt_40hz <= {CNTR_WIDTH{1'b0}};
        end
        else if (clk_cnt_40hz == top_cnt_40hz) begin
            tick40hz <= 1'b1;
            clk_cnt_40hz <= {CNTR_WIDTH{1'b0}};
        end
        else begin
            clk_cnt_40hz <= clk_cnt_40hz + 1'b1;
            tick40hz <= 1'b0;
        end
    end // update clock enable

	// generate 50Hz clock enable
	always @(posedge clk) begin
		if (reset) begin
			clk_cnt_50hz <= {CNTR_WIDTH{1'b0}};
		end
		else if (clk_cnt_50hz == top_cnt_50hz) begin
		    tick50hz <= 1'b1;
		    clk_cnt_50hz <= {CNTR_WIDTH{1'b0}};
		end
		else begin
		    clk_cnt_50hz <= clk_cnt_50hz + 1'b1;
		    tick50hz <= 1'b0;
		end
	end // update clock enable
	
//------------------acceleration calculation block-------------------//
// 
// calculating speed based on up and down push button inputs 
// and enabling acceleration or deceleration flags to control speed
// by reading the push buttons at a rate of 50Hz
// 
always @(posedge clk) begin
    if(reset) begin
        acceleration        <= 8'd0;
        deceleration_flag   <= 1'd0;
        acceleration_flag   <= 1'd0;
    end
    else if(tick50hz) begin
        if(pBtns[1]) begin
            if(acceleration == 8'd255) begin
                acceleration <= acceleration;
                acceleration_flag <= 1'd0;
                deceleration_flag <= 1'd1;
            end
            else begin
                acceleration <= acceleration + 8'd1;
                acceleration_flag <= 1'd0;
                deceleration_flag <= 1'd1;
            end
        end
        else if(pBtns[3]) begin
            if(acceleration == 8'd255) begin
                acceleration <= acceleration;
                acceleration_flag <= 1'd1;
                deceleration_flag <= 1'd0;
            end
            else begin
                acceleration <= acceleration + 8'd1;
                acceleration_flag <= 1'd1;
                deceleration_flag <= 1'd0;
            end
        end
        else begin
            acceleration <= 8'd0;
            acceleration_flag <= 1'd0;
            deceleration_flag <= 1'd1;
        end
    end
end

//------------------speed calculation block-------------------//
// 
// calculating speed based on acceleration or deceleration flag 
// and different ranges of acceleration register
// which is in turn used to calculate distance
// 
always @(posedge clk) begin
    if(reset) begin
        speed        <= 8'd0;
    end
    else if(tick50hz) begin
        if(deceleration_flag) begin
            if(speed > 8'd8) begin
                if(acceleration > 8'd63) begin
                    speed <= speed - 8'd2;
                end
                else if(acceleration > 8'd127) begin
                    speed <= speed - 8'd4;
                end
                else if(acceleration > 8'd191) begin
                    speed <= speed - 8'd8;
                end
                else begin
                    speed <= speed - 8'd1;
                end
            end
            else begin
                speed <= 8'd0;
            end
        end
        else if(acceleration_flag) begin
            if(speed < 8'd248) begin
                if(acceleration > 8'd191 ) begin
                    speed <= speed + 8'd8;
                end
                else if(acceleration > 8'd127) begin
                    speed <= speed + 8'd4;
                end
                else if(acceleration > 8'd63) begin
                    speed <= speed + 8'd2;
                end
                else begin
                    speed <= speed + 8'd1;
                end
            end
            else begin
                speed <= 8'd255;
            end
        end
    end
end

//------------------distance calculation block-------------------//
// 
// calculating distance based on different ranges of speed 
// which is in turn used to calculate score
// 
always @(posedge clk) begin
    if (reset) begin
        distance <= 16'd0;
    end
    else if(tick50hz) begin
        if(distance < (DIST_MAX - 16'd8)) begin
            if(speed < 8'd64) begin
                distance <= distance + 16'd1;
            end
            else if(speed < 8'd128) begin
                distance <= distance + 16'd2;
            end
            else if(speed < 8'd192) begin
                distance <= distance + 16'd4;
            end
            else begin
                distance <= distance + 16'd8;
            end
        end
        else begin
            distance <= DIST_MAX;
        end
    end
end

//------------------background ICON selection block-------------------//
// 
// calculating which background to select based on speed calculated in the above always blocks.
// also changing different backgrounds depending on different speed ranges using 
// clock enable signals generated at the beginning of the file
// 
always @(posedge clk) begin
    if (reset) begin
        background_num <= 3'd0;
    end
    else if(speed == 8'd0) begin
        background_num <= background_num;
    end
    else if(speed < 8'd64) begin
        if(tick5hz) begin
            background_num <= background_num + 3'd1;
        end
        else begin
            background_num <= background_num;
        end
    end
    else if(speed < 8'd128) begin
        if(tick10hz) begin
            background_num <= background_num + 3'd1;
        end
        else begin
            background_num <= background_num;
        end
    end
    else if(speed < 8'd192) begin
        if(tick20hz) begin
            background_num <= background_num + 3'd1;
        end
        else begin
            background_num <= background_num;
        end
    end
    else begin
        if(tick40hz) begin
            background_num <= background_num + 3'd1;
        end
        else begin
            background_num <= background_num;
        end
    end
end

//------------------bike icon position always block-------------------//
// 
// calculating bike column position based on left and right push buttons.
// we are checking push buttons input with a frequency of 50Hz and then varying 
// column position of the bike and sending it to icon module to display bike at that position
// 
always @(posedge clk) begin
    if(reset) begin
        bike_col_position <= BIKE_INIT_COL;
    end
    else if(tick50hz) begin
        if(pBtns[2]) begin
            if(bike_col_position < BIKE_MAX_COL - BIKE_COL_CHANGE) begin
                bike_col_position <= bike_col_position + BIKE_COL_CHANGE;
            end
            else begin
                bike_col_position <= BIKE_MAX_COL;
            end
        end
        else if(pBtns[4]) begin
            if(bike_col_position > BIKE_COL_CHANGE) begin
                bike_col_position <= bike_col_position - BIKE_COL_CHANGE;
            end
            else begin
                bike_col_position <= BIKE_MIN_COL;
            end
        end
        else begin
            bike_col_position <= bike_col_position;
        end
    end
end

//------------------left car icon control signal always block-------------------//
// 
// selecting different positions for different places of screen so that 
// we achieve that 3D illusion for each position in the display
// and set left_car_icon_num which acts as a control number in icon module for displaying left car
// 
always @(posedge clk) begin
	if(reset) begin
		left_car_row <= ROW_MAX;
		left_car_column <= COLUMN_MAX;
		left_car_icon_num <= 3'd0;
	end
	else if(tick50hz) begin
        if(left_obstacle_flag) begin
            left_car_row <= LEFT_CAR_ROW_INIT;
            left_car_column <= LEFT_CAR_COL_INIT;
    		left_car_icon_num <= 3'd0;
        end
        else if(left_car_column < (COLUMN_MIN + 10'd5)) begin
            left_car_row <= left_car_row;
            left_car_column <= left_car_column;
            left_car_icon_num <= 3'd0;
        end
        else if(left_car_row < LEFT_CAR_POSITION_2) begin
            left_car_row <= left_car_row + 10'd1;
            left_car_column <= left_car_column - 10'd2;
            left_car_icon_num <= 3'd1;
        end
        else if(left_car_row < LEFT_CAR_POSITION_3) begin
            left_car_row <= left_car_row + 10'd1;
            left_car_column <= left_car_column - 10'd3;
            left_car_icon_num <= 3'd2;
        end
        else if(left_car_row == LEFT_CAR_POSITION_3) begin
            left_car_row <= left_car_row + 10'd1;
            left_car_column <= LEFT_CAR_COL_POSITION_4;
            left_car_icon_num <= 3'd3;
        end
        else if(left_car_row < LEFT_CAR_POSITION_4) begin
            left_car_row <= left_car_row + 10'd1;
            left_car_column <= left_car_column - 10'd4;
            left_car_icon_num <= 3'd3;
        end
        else if(left_car_row == LEFT_CAR_POSITION_4) begin
            left_car_row <= left_car_row + 10'd1;
            left_car_column <= LEFT_CAR_COL_POSITION_5;
            left_car_icon_num <= 3'd4;
        end
        else if(left_car_row < LEFT_CAR_POSITION_5) begin
            left_car_row <= left_car_row + 10'd1;
            left_car_column <= left_car_column - 10'd5;
            left_car_icon_num <= 3'd4;
        end
        else if(left_car_row < LEFT_CAR_POSITION_6) begin
            left_car_row <= left_car_row + 10'd1;
            left_car_column <= left_car_column - 10'd6;
            left_car_icon_num <= 3'd5;
        end
        else begin
            left_car_row <= left_car_row;
            left_car_column <= left_car_column;
            left_car_icon_num <= 3'd0;
        end
    end
end

//------------------right car icon control signal always block-------------------//
// 
// selecting different positions for different places on screen so that 
// we achieve that 3D illusion for each position in the display
// and set right_car_icon_num which acts as a control number in icon module for displaying right car
// 
always @(posedge clk) begin
	if(reset) begin
	    right_car_row <= ROW_MAX;
		right_car_column <= COLUMN_MAX;
	end
	else if(tick50hz) begin
        if(right_obstacle_flag) begin
            right_car_row <= RIGHT_CAR_ROW_INIT;
            right_car_column <= RIGHT_CAR_COL_INIT;
    		right_car_icon_num <= 3'd0;
        end
        else if(right_car_column > (COLUMN_MAX - 10'd5)) begin
            right_car_row <= right_car_row;
            right_car_column <= right_car_column;
            right_car_icon_num <= 3'd0;
        end
        else if(right_car_row < RIGHT_CAR_POSITION_2) begin
            right_car_row <= right_car_row + 10'd1;
            right_car_column <= right_car_column + 10'd2;
            right_car_icon_num <= 3'd1;
        end
        else if(right_car_row < RIGHT_CAR_POSITION_3) begin
            right_car_row <= right_car_row + 10'd1;
            right_car_column <= right_car_column + 10'd3;
            right_car_icon_num <= 3'd2;
        end
        else if(right_car_row < RIGHT_CAR_POSITION_4) begin
            right_car_row <= right_car_row + 10'd1;
            right_car_column <= right_car_column + 10'd4;
            right_car_icon_num <= 3'd3;
        end
        else if(right_car_row < RIGHT_CAR_POSITION_5) begin
            right_car_row <= right_car_row + 10'd1;
            right_car_column <= right_car_column + 10'd5;
            right_car_icon_num <= 3'd4;
        end
        else if(right_car_row < RIGHT_CAR_POSITION_6) begin
            right_car_row <= right_car_row + 10'd1;
            right_car_column <= right_car_column + 10'd6;
            right_car_icon_num <= 3'd5;
        end
        else begin
            right_car_row <= right_car_row;
            right_car_column <= right_car_column;
            right_car_icon_num <= 3'd0;
        end
    end
end

//------------------middle car icon control signal always block-------------------//
// 
// selecting different positions for different places of screen so that 
// we achieve that 3D illusion for each position in the display
// and set middle_car_icon_num which acts as a control number in icon module for displaying middle car
// 
always @(posedge clk) begin
	if(reset) begin
		middle_car_row <= MIDDLE_CAR_ROW_INIT;
		middle_car_column <= MIDDLE_CAR_COL_INIT;
		middle_car_icon_num <= 3'd0;
	end
	else if(tick50hz) begin
        if(obstacle_flag) begin
            middle_car_row <= MIDDLE_CAR_ROW_INIT;
            middle_car_column <= MIDDLE_CAR_COL_INIT;
    		middle_car_icon_num <= 3'd0;
        end
        else if(middle_car_row < MIDDLE_CAR_POSITION_2) begin
            middle_car_row <= middle_car_row + 10'd1;
            middle_car_column <= MIDDLE_CAR_COL_POSITION_2;
            middle_car_icon_num <= 3'd1;
        end
        else if(middle_car_row < MIDDLE_CAR_POSITION_3) begin
            middle_car_row <= middle_car_row + 10'd1;
            middle_car_column <= MIDDLE_CAR_COL_POSITION_3;
            middle_car_icon_num <= 3'd2;
        end
        else if(middle_car_row < MIDDLE_CAR_POSITION_4) begin
            middle_car_row <= middle_car_row + 10'd1;
            middle_car_column <= MIDDLE_CAR_COL_POSITION_4;
            middle_car_icon_num <= 3'd3;
        end
        else if(middle_car_row < MIDDLE_CAR_POSITION_5) begin
            middle_car_row <= middle_car_row + 10'd1;
            middle_car_column <= MIDDLE_CAR_COL_POSITION_5;
            middle_car_icon_num <= 3'd4;
        end
        else if(middle_car_row < MIDDLE_CAR_POSITION_6) begin
            middle_car_row <= middle_car_row + 10'd1;
            middle_car_column <= MIDDLE_CAR_COL_POSITION_6;
            middle_car_icon_num <= 3'd5;
        end
        else begin
            middle_car_row <= middle_car_row;
            middle_car_column <= middle_car_column;
            middle_car_icon_num <= 3'd0;
        end
    end
	else begin
        middle_car_row <= middle_car_row;
        middle_car_column <= middle_car_column;
        middle_car_icon_num <= 3'd0;
    end
end
endmodule
