`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:36:28 03/12/2018
// Design Name:   Snake_remix
// Module Name:   C:/Users/152/Downloads/lab4_snek/Snake_tb.v
// Project Name:  lab4_snek
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Snake_remix
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Snake_tb;

	// Inputs
	reg clk;
	reg rst;
	reg [3:0] JC;

	// Outputs
	wire out_clk;
	wire [6:0] randomX;
	wire [6:0] randomY;
	wire [2:0] normal;
	wire [3:0] direction;

	// Clock divider to make 25HZ clock
	Clock_divider #(4) clock_test (
		.clk(clk), 
		.rst(rst), 
		.out_clk(out_clk)
	);
	
	Random random_test (
		.clk(out_clk),
		.randX(randomX),
		.randY(randomY),
		.normal(normal)
	);
	
	Button_input button_test (
		.clk(clk),
		.up(JC[0]),
		.down(JC[3]),
		.left(JC[2]),
		.right(JC[1]),
		.direction(direction)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		JC = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		//Reset testing
		#50 rst = 1;
		#10 rst = 0;
		
		
		
		//Direction testing
		
		// direction is initially down
		// cannot turn 180
		#50 JC = 0; JC[0] = 1; // up
		// stays down if same direction input
		#50 JC = 0; JC[3] = 1; // down
		// can turn
		#50 JC = 0; JC[2] = 1; // left
		// cannot turn 180
		#50 JC = 0; JC[1] = 1; // right
		// stays in same direction
		#50 JC = 0; JC[2] = 1; // left
		// can turn
		#50 JC = 0; JC[0] = 1; // up
		
		#50 JC = 0;
		

	end
	
	always begin
		#5 clk = ~clk;
	end
      
endmodule

