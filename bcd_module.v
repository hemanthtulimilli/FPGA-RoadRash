`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Project Name: RoadRash
// Engineer: Venkata Hemanth Tulimilli
// 
// Create Date: 06/09/2015 02:14:28 AM
// Module Name: bcd_module
// Target Devices: Nexys4DDR
// Description: This module takes the input from main controller and extracts individual digits 
// and send those values to icon module to display it on the screen.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// This file is totally dependent on main logic file where we give out speed and score values.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module bcd_module(
    input       clk,
    input       reset,
    input [19:0] score,
    input [7:0] speed,
    output reg [3:0] speed_hunds,
    output reg [3:0] speed_tens,
    output reg [3:0] speed_ones,
    output reg [3:0] score_ones,
    output reg [3:0] score_tens,
    output reg [3:0] score_hunds,
    output reg [3:0] score_thous,
    output reg [3:0] score_tenthous,
    output reg [3:0] score_hundthous
    );
    
	// local variables for calculation
    reg [7:0]   speed_temp;
    reg [19:0]  score_temp;

//------------------individual speed numbers extraction block-------------------//
// 
// calculate individual bits of speed value and 
//send it back to icon module to display them on the screen
// 
always @(*) begin
    speed_temp = speed;
    speed_ones = speed_temp % 8'd10;
    speed_temp = speed_temp / 8'd10;
    speed_tens = speed_temp % 8'd10;
    speed_temp = speed_temp / 8'd10;
    speed_hunds = speed_temp;
end

//------------------individual score numbers extraction block-------------------//
// 
// calculate individual bits of score value and 
//send it back to icon module to display them on the screen
// 
always @(*) begin
    score_temp = score;
    score_ones = score_temp % 20'd10;
    score_temp = score_temp / 20'd10;
    score_tens = score_temp % 20'd10;
    score_temp = score_temp / 20'd10;
    score_hunds = score_temp % 20'd10;
    score_temp = score_temp / 20'd10;
    score_thous = score_temp % 20'd10;
    score_temp = score_temp / 20'd10;
    score_tenthous = score_temp % 20'd10;
    score_temp = score_temp / 20'd10;
    score_hundthous = score_temp % 20'd10;
end
endmodule
