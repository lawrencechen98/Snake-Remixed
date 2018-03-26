module Snake_remix (clk, rst, JC, Hsync, Vsync, vgaRed, vgaGreen, vgaBlue, seg, an);
	// parameter for max size of snake
	parameter MAX_SIZE = 128;
	
	input clk, rst;
	
	// key pads input
	input [7:0] JC; 

	// seven segment display
	output reg [3:0] an;
	output reg [7:0] seg;

	// VGA output
	output wire Hsync, Vsync;
	output wire [2:0] vgaRed, vgaGreen;
	output wire [1:0] vgaBlue;

	// temp wires for display
	wire [7:0] temp_seg;
	wire [7:0] temp_an;
	
	// temp wires for VGA
	wire R, G, B;
	
	// different clocks
	wire VGA_clk;		// clock for VGA display update
	wire update_clk;	// clock for game object update
	wire power_clk; 	// clock for snake update if powered up
	wire fast_clk; 		// clock for seven segment display

	// for pixel display
	wire inBounds; // is part of game map
	wire [9:0] xCount, yCount; // pixels

	// random coordinates
	wire [9:0] randX, randY;
	// value of whether food is normal or power up
	wire [2:0] normal;	

	// game over states
	reg game_over;
	reg blue_died;
	reg red_died;

	// game object existence
	reg food, border;
	// food location
	reg [6:0] foodX;
	reg [6:0] foodY;
	reg super_food;

	// snake body location and existence
	reg [6:0] snakeX[0:MAX_SIZE-1];
  	reg [6:0] snakeY[0:MAX_SIZE-1];
  	reg [MAX_SIZE-1:0] snakeBody;
	
	// second snake body location and existence
	reg [6:0] snakeXB[0:MAX_SIZE-1];
  	reg [6:0] snakeYB[0:MAX_SIZE-1];
  	reg [MAX_SIZE-1:0] snakeBodyB;

  	// snake lengths
  	reg [6:0] length;
	reg [6:0] lengthB;
	// snake directions
	wire [3:0] direction;
	wire [3:0] directionB;
	// snake power up count
	reg [6:0] power;
	reg [6:0] powerB;

	// get clocks with clock divider
	Clock_divider #(4) divider(clk, rst, VGA_clk); // 25 MHz
	Clock_divider #(30000) fast(VGA_clk, rst, fast_clk);
	Clock_divider #(3600000) update(VGA_clk, rst, update_clk);
	Clock_divider #(1800000) powered(VGA_clk, rst, power_clk);

	// generate random coordinates
	Random rand(clk, randX, randY, normal);
	
	// process key pad input into direction bits
	Button_input dir(.clk(clk), .up(JC[4]), .down(JC[7]), .left(JC[6]), .right(JC[5]), .direction(direction));
	Button_input dirB(.clk(clk), .up(JC[0]), .down(JC[3]), .left(JC[2]), .right(JC[1]), .direction(directionB));
	
	// module for handling VGA display
	VGA_gen vga(VGA_clk, xCount, yCount, inBounds, Hsync, Vsync);
	
	// module for handling seven segment display to show winner
	Segment_display display(.clk(fast_clk), .blue(blue_died), .red(red_died), .an(temp_an), .seg(temp_seg));

	// for snake body iteration
	integer count;

	always@(posedge VGA_clk or posedge rst) begin
    	
    	if (rst) begin
      		// reset game object locations
      		snakeX[0] <= 30;
      		snakeY[0] <= 25;
			snakeXB[0] <= 50;
      		snakeYB[0] <= 35;
      		foodX <= 40;
			foodY <= 30;

      		for(count = 1; count < MAX_SIZE; count = count + 1) begin
          		// place unseen snake body outside of display area
          		snakeX[count] <= 127;
          		snakeY[count] <= 127;
				snakeXB[count] <= 126;
          		snakeYB[count] <= 126;
        	end

        	//reset game attributes
      		length <= 1;
			lengthB <= 1;
			power <= 0;
			powerB <= 0;
      		game_over <= 0;
			blue_died <= 0;
			red_died <= 0;
    	end 

    	else if (~game_over) begin
      	
      		if (update_clk || (power_clk && (power || powerB))) begin // if clock is high, update moving game parts 

      			if ((update_clk && !power) ||  (power_clk && power)) begin 
	      			// update each body part to coordinate of next body part coordinate, simulate movement
	        		for(count = 1; count < MAX_SIZE; count = count + 1) begin
	            		if(count < length) begin
	              			snakeX[count] <= snakeX[count - 1];
	              			snakeY[count] <= snakeY[count - 1];
	            		end
	          		end
	          		// move snake head one pixel depending on snake's direction state
	        		case(direction)
	          			4'b0001: snakeX[0] <= (snakeX[0] - 1);
	          			4'b0010: snakeX[0] <= (snakeX[0] + 1);
	          			4'b0100: snakeY[0] <= (snakeY[0] - 1);
	          			4'b1000: snakeY[0] <= (snakeY[0] + 1);
	        		endcase

	        		// if snake is powered up, reduce power count by 1
	        		if (power != 0) begin
	        			power <= power - 1;
	        		end
	        	end 

	        	if ((update_clk && !powerB) ||  (power_clk && powerB)) begin 
	        		// update each body part to coordinate of next body part coordinate, simulate movement
	        		for(count = 1; count < MAX_SIZE; count = count + 1) begin
						if(count < lengthB) begin
	              			snakeXB[count] <= snakeXB[count - 1];
	              			snakeYB[count] <= snakeYB[count - 1];
	            		end
	          		end
	          		// move snake head one pixel depending on snake's direction state
					case(directionB)
	          			4'b0001: snakeXB[0] <= (snakeXB[0] - 1);
	          			4'b0010: snakeXB[0] <= (snakeXB[0] + 1);
	          			4'b0100: snakeYB[0] <= (snakeYB[0] - 1);
	          			4'b1000: snakeYB[0] <= (snakeYB[0] + 1);
	        		endcase

	        		// if snake is powered up, reduce power count by 1
	        		if (powerB != 0) begin
	        			powerB <= powerB - 1;
	        		end
	        	end
      		end 

      		else begin // if not movement updates, check game state 

        		// if snake head is at same coordinate as the food object, increase snake length and reset food location
        		if ((snakeX[0] == foodX) && (snakeY[0] == foodY)) begin
          			foodX <= randX;
          			foodY <= randY;

          			// if food is special, gain 5 power counts instead
            		if (super_food)
            			power <= power + 100;
            		// else increase length
            		else if (length < MAX_SIZE - 4)
            			length <= length + 4;

            		super_food <= !normal;
            	end
        		//  if snake touches border, game is over and the corresponding snake is stated as dead     
        		else if ((snakeX[0] == 10) || (snakeX[0] == 69) || (snakeY[0] == 10) || (snakeY[0] == 49)) begin
          			game_over <= 1'b1;
					red_died <= 1'b1;
				end
        		// check if snake touches own body or other snake, and set game attributes accordingly
        		else if ((|snakeBody[MAX_SIZE-1:1] || |snakeBodyB[MAX_SIZE-1:0])&& snakeBody[0]) begin
          			game_over <= 1'b1;
					red_died <= 1'b1;
				end

      			// check for food object again for second snake
				if ((snakeXB[0] == foodX) && (snakeYB[0] == foodY)) begin
          			foodX <= randX;
          			foodY <= randY;
          			
          			// if food is special, gain 5 power counts instead
          			if (super_food)
            			powerB <= powerB + 100;
            		// else increase length instead
            		else if (lengthB < MAX_SIZE - 4)
            			lengthB <= lengthB + 4;

            		super_food <= !normal;
        		end
        		// check if second snake hits border, and if so set game attributes accordingly       
        		else if ((snakeXB[0] == 10) || (snakeXB[0] == 69) || (snakeYB[0] == 10) || (snakeYB[0] == 49)) begin
          			game_over <= 1'b1;
					blue_died <= 1'b1;
				end
        		// check if second snake hits own body or other snake
        		else if ((|snakeBodyB[MAX_SIZE-1:1] || |snakeBody[MAX_SIZE-1:0])&& snakeBodyB[0]) begin
          			game_over <= 1'b1;
					blue_died <= 1'b1;
				end
      		end
    	end
  	end

  	// draw border by checking if VGA display is currently at border coordinates
  	// draw food if VGA display is currently at food coordinates
  	always @(posedge VGA_clk) begin
    	border <= ((((xCount[9:3] == 10) || (xCount[9:3] == 69)) && (yCount[9:3] >= 10) && (yCount[9:3] <= 49)) || (((yCount[9:3] == 10) || (yCount[9:3] == 49)) && (xCount[9:3] <= 69) && (xCount[9:3] >= 10)));
  		food <= (xCount[9:3] == foodX) && (yCount[9:3] == foodY);
  	end

  	// draw snake bodies if VGA display currently at a snake body part's coordinate
  	always@(posedge VGA_clk) begin
    	for(count = 0; count < MAX_SIZE; count = count + 1) begin
      		snakeBody[count] <= (xCount[9:3] == snakeX[count]) & (yCount[9:3] == snakeY[count]);
			snakeBodyB[count] <= (xCount[9:3] == snakeXB[count]) & (yCount[9:3] == snakeYB[count]);
		end
	end
	
	// set display anodes and segments to temporary wire outputs of segment display module
	always @ (*) begin
		seg <= temp_seg;
		an <= temp_an;
	end
	
	// set color values for pixels depending on presence of game parts if display is currently in bounds
  	assign R = (inBounds && ((|snakeBody && ~game_over) || food || game_over));
  	assign G = (inBounds && (border && ~game_over) || (food && super_food && ~game_over));
  	assign B = (inBounds && ((|snakeBodyB && ~game_over) || (food && ~game_over)));
  	// assign the color values to corresponding VGA pixel outputs
    assign vgaRed = {3{R}};
    assign vgaGreen = {3{G}};
    assign vgaBlue = {2{B}};

endmodule // Snake_remix


module Clock_divider(clk, rst, out_clk);
	// clock divider factor parameter
	parameter FACTOR = 1;
	
	input clk, rst;
	output out_clk;
	reg [31:0] count;
	reg clk_reg;

	initial begin
		count = 0;
		clk_reg = 0;
	end

	always @(posedge clk or posedge rst) begin
		if (rst == 1) begin
			count <= 0;
			clk_reg <= 0;
		end 
		else if (count == FACTOR - 1) begin
			count <= 0;
			clk_reg <= 1;
		end 
		else begin
			count <= count + 1;
			clk_reg <= 0;
		end
	end

	assign out_clk = clk_reg;

endmodule // Clock_divider

module Segment_display(clk, blue, red, an, seg);
	
	input clk;
	// is blue dead? is red dead?
	input blue, red;
	output [7:0] seg;
	output [3:0] an;
	
	reg [7:0] segments;
	reg [3:0] anodes;
	
	reg [1:0] count;
	
	always @ (posedge clk) begin
		if (blue && red) begin
			case (count)
				0:begin
					anodes <= 4'b0111;
					segments <= 8'b10000111; // 't'
				end
				1:begin
					anodes <= 4'b1011;
					segments <= 8'b11111011; // 'i'
				end
				2:begin
					anodes <= 4'b1101;
					segments <= 8'b10000100; // 'e'
				end
				3:begin
					anodes <= 4'b1110;
					segments <= 8'b11111111; // empty
				end
			endcase
		end 
		else if (blue) begin
			case (count)
				0:begin
					anodes <= 4'b0111;
					segments <= 8'b11001110; // 'r'
				end
				1:begin
					anodes <= 4'b1011;
					segments <= 8'b10000100; // 'e'
				end
				2:begin
					anodes <= 4'b1101;
					segments <= 8'b10100001; // 'd'
				end
				3:begin
					anodes <= 4'b1110;
					segments <= 8'b11111111; // empty
				end
			endcase
		end
		else if (red) begin
			case (count)
				0:begin
					anodes <= 4'b0111;
					segments <= 8'b10000011; // 'b'
				end
				1:begin
					anodes <= 4'b1011;
					segments <= 8'b11001111; // 'l'
				end
				2:begin
					anodes <= 4'b1101;
					segments <= 8'b11000001; // 'u'
				end
				3:begin
					anodes <= 4'b1110;
					segments <= 8'b10000100; //  'e'
				end
			endcase
		end
		else begin
			case (count)
				0:begin
					anodes <= 4'b0111;
					segments <= 8'b10111111; // '-'
				end
				1:begin
					anodes <= 4'b1011;
					segments <= 8'b10111111; // '-'
				end
				2:begin
					anodes <= 4'b1101;
					segments <= 8'b10111111; // '-'
				end
				3:begin
					anodes <= 4'b1110;
					segments <= 8'b10111111; //  '-'
				end
			endcase
		end
		
		count <= count + 1;
	end
	
	assign an = anodes;
	assign seg = segments;
	
endmodule // Segment_display

module Button_input(clk, up, down, left, right, direction);
	input clk, up, down, left, right;
	output reg [3:0] direction;
	
	initial begin
		direction = 4'b1000;
	end

	always @ (posedge clk) begin
		if (left == 1 && direction != 4'b0010) 
			direction <= 4'b0001; // left
		else if (right == 1 && direction != 4'b0001) 
			direction <= 4'b0010; // right
		else if (up == 1 && direction != 4'b1000) 
			direction <= 4'b0100; // up
		else if (down == 1 && direction != 4'b0100) 
			direction <= 4'b1000; // down
		else
			direction <= direction;
	end
endmodule // Button_input


module Random(clk, randX, randY, normal);
	input clk;
	output reg [6:0] randX;
	output reg [6:0] randY;
	output reg [2:0] normal;

	initial begin
		randX <= 7'b0000000;
		randY <= 7'b0000000;
		normal <= 3'b000;
	end

	always @ (posedge clk) begin  
		randX <= ((randX + 7) % 58) + 11;
		randY <= ((randY + 5) % 38) + 11;
		normal <= ((normal + 5) % 9);
	end

endmodule // Random


module VGA_gen(VGA_clk, xCount, yCount, displayArea, VGA_hSync, VGA_vSync);

	input VGA_clk;
	output reg [9:0]xCount, yCount; 
	output reg displayArea;  
	output VGA_hSync, VGA_vSync;

	reg p_hSync, p_vSync; 

	integer porchHF = 640;	//start of horizntal front porch
	integer syncH = 656;		//start of horizontal sync
	integer porchHB = 752;	//start of horizontal back porch
	integer maxH = 799;		//total length of line.

	integer porchVF = 480;	//start of vertical front porch 
	integer syncV = 490;		//start of vertical sync
	integer porchVB = 492; 	//start of vertical back porch
	integer maxV = 525;		//total rows. 

	always @ (posedge VGA_clk) begin
		if(xCount == maxH)
			xCount <= 0;
		else
			xCount <= xCount + 1;
	end
	always @ (posedge VGA_clk) begin
		if(xCount == maxH) begin
			if(yCount == maxV)
				yCount <= 0;
			else
				yCount <= yCount + 1;
		end
	end

	always @ (posedge VGA_clk) begin
		displayArea <= ((xCount < porchHF) && (yCount < porchVF)); 
	end

	always @ (posedge VGA_clk) begin
		p_hSync <= ((xCount >= syncH) && (xCount < porchHB)); 
		p_vSync <= ((yCount >= syncV) && (yCount < porchVB)); 
	end

	assign VGA_vSync = ~p_vSync; 
	assign VGA_hSync = ~p_hSync;

endmodule // VGA_gen