# Snake: Remixed

### Remix of the classic Snake game written in Verilog for Xilinx FPGA

##### This repo contains the top level Verilog source code, the testbench, and the Nexys.ucf file.


### How is it remixed?

##### The game has been turned into a 2 player versus game, in which two snakes appear on the game board. The objective of the game is to eat food to grow longer and "dominate" more of the playing field. If a snake crashes into the border of the game map, its own body, or the body of the opponent, that snake loses. The snake that is still alive loses.

![Picture of Gameplay](../master/images/game1.jpg =250x)


##### The game also introduces new "power up" food, which are colored white as shown below. The food, instead of making the snake longer, makes the snake who ate it significantly faster for a short period of time. This boost allows the owner of this power up to better obtain more food or maneuver to a position of advantage against the other snake. 

![Picture of Gameplay featuring Power-up](../master/images/game2.jpg)


##### The snakes are controlled by two keypads, each with four buttons. They control the directions of their corresponding snake to go 'up', 'down', 'left', and 'right'.

![Controller](../master/images/controls.jpeg)


##### Finally, the winner of the round is displayed on the seven-segment display on the FPGA board itself. The middle button of the 'D-pad' is used to reset the game at any time to restart a new round, usually used after a snake dies and the game is over.

![Board with Blue Snake Winner](../master/images/winner.jpg)


### Happy gaming!
##### Hope you enjoy this new remix of the classic game.
