
module frogger_graph 
   (
    input wire clk, reset,
    input wire [3:0] motion_cmd,
    input wire [9:0] pix_x, pix_y,
    input wire gra_still,
    output wire graph_on,
    output reg hit, miss,
    output reg [2:0] graph_rgb,
	output wire refr_tick
   );

   // costant and signal declaration
   // x, y coordinates (0,0) to (639,479)
   localparam MAX_X = 640;
   localparam MAX_Y = 480;
   //wire refr_tick;
   //--------------------------------------------
   // Horizontal strips as a wall
   //--------------------------------------------
   // Upper Side Walk up, down boundary
   localparam UPPER_SIDE_WALK_Y_U = 0;
   localparam UPPER_SIDE_WALK_Y_B = 95;
   // Middle Side Walk up, down boundary
   localparam MID_SIDE_WALK_Y_U = 215;
   localparam MID_SIDE_WALK_Y_B = 263;
   // Bottom Side Walk up, down boundary
   localparam BTM_SIDE_WALK_Y_U = 383;
   localparam BTM_SIDE_WALK_Y_B = 479;
   //--------------------------------------------
   // street bar
   //--------------------------------------------
   // bar up, top boundary
   localparam BAR1_Y_T = 143;
   localparam BAR1_Y_B = 167;
   localparam BAR2_Y_T = 311;
   localparam BAR2_Y_B = 335;
   // bar top, bottom boundary
   localparam BAR_X_1  = 50;
   localparam BAR_X_2  = 100;
   localparam BAR_X_3  = 150;
   localparam BAR_X_4  = 200;
   localparam BAR_X_5  = 250;
   localparam BAR_X_6  = 300;
   localparam BAR_X_7  = 350;
   localparam BAR_X_8  = 400;
   localparam BAR_X_9  = 450;
   localparam BAR_X_10 = 500;
   localparam BAR_X_11  = 550;
   localparam BAR_X_12  = 600;
   localparam BAR_X_13  = 650;
   /////////////////////////////////
   // Cars (later)
   ////////////////////////////////
   localparam CAR_X_SIZE = 72;
   // car top , bottom boundary
   localparam CAR1_Y_T = 100;//+
   localparam CAR1_Y_B = 138;//_
   localparam CAR2_Y_T = 177;
   localparam CAR2_Y_B = 205;
   localparam CAR3_Y_T = 273;
   localparam CAR3_Y_B = 301;
   localparam CAR4_Y_T = 345;
   localparam CAR4_Y_B = 372;
   // car left , right boundary
   wire [9:0] car_x_l,car_x_r;
	wire [9:0] car1_x_l,car1_x_r;
	wire [9:0] car2_x_l,car2_x_r;
	wire [9:0] car3_x_l,car3_x_r;
	wire [9:0] car4_x_l,car4_x_r;
	wire [9:0] car5_x_l,car5_x_r;
	wire [9:0] car6_x_l,car6_x_r;
	wire [9:0] car7_x_l,car7_x_r;
   // register to track top boundary  (x position is fixed)
   reg [9:0] car_x_reg_r, car_x_next_r;
   reg [9:0] car_x_reg_l, car_x_next_l;
   // car moving velocity
   localparam CAR_V = 6;
   //--------------------------------------------
   // square frog
   //--------------------------------------------
   localparam FROG_SIZE = 32;
   // frog left, right boundary
   wire [9:0] frog_x_l, frog_x_r;
   // ball top, bottom boundary
   wire [9:0] frog_y_t, frog_y_b;
   // reg to track left, top position
   reg [9:0] frog_x_reg, frog_y_reg;
   wire [9:0] frog_x_next, frog_y_next;
   // reg to track frog speed
   reg [9:0] x_delta_reg, x_delta_next;
   reg [9:0] y_delta_reg, y_delta_next;
   // frog velocity can be pos or neg)
   localparam FROG_V_P = 5;
   localparam FROG_V_N = -5;
   //--------------------------------------------
   // round frog
   //--------------------------------------------
   wire [3:0] rom_addr, rom_col;
   reg [15:0] rom_data;
   wire rom_bit;
   //--------------------------------------------
   // object output signals
   //--------------------------------------------
   wire side_on, bar_on, sq_frog_on, rd_frog_on, car_on;
   wire [2:0] side_rgb, bar_rgb, frog_rgb,car_rgb;
  
   // body 
   //--------------------------------------------
   // round frog image ROM
   //--------------------------------------------
   always @*
   case (rom_addr)
      4'h0: rom_data = 16'b1100001111000011; // 0001111000
      4'h1: rom_data = 16'b1100011111100011; // 0000110000
      4'h2: rom_data = 16'b1100011111100011; // 0001111000
      4'h3: rom_data = 16'b1111111111111111; // 0001111000
      4'h4: rom_data = 16'b1111111111111111; // 0001111000
      4'h5: rom_data = 16'b0000111111110000; // 0001111000
      4'h6: rom_data = 16'b0001111111111000; // 0001111000
      4'h7: rom_data = 16'b1111111111111111; // 0001111000
      4'h8: rom_data = 16'b1111111111111111; // 0001111000
      4'h9: rom_data = 16'b1111111111111111; // 0001111000
	  4'ha: rom_data = 16'b1111111111111111; 
	  4'hb: rom_data = 16'b1111111111111111; 
	  4'hc: rom_data = 16'b1100001111000011; 
	  4'hd: rom_data = 16'b1100000110000011; 
	  4'he: rom_data = 16'b1100000000000011;
	  4'hf: rom_data = 16'b1100000000000011;  
    endcase
   
   // registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            car_x_reg_r <= 100;
			car_x_reg_l <= 600;
            frog_x_reg <= 10'd320;
            frog_y_reg <= 10'd413;
            x_delta_reg <= 10'd000;
            y_delta_reg <= 10'h000;
         end   
      else
         begin
            car_x_reg_r <= car_x_next_r;
			car_x_reg_l <= car_x_next_l;
            frog_x_reg <= frog_x_next;
            frog_y_reg <= frog_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
         end   

   // refr_tick: 1-clock tick asserted at start of v-sync
   //       i.e., when the screen is refreshed (60 Hz)
   assign refr_tick = (pix_y==481) && (pix_x==0);
   
   //--------------------------------------------
   // (side) horizontal strips
   //--------------------------------------------
   // pixel within wall
   assign side_on = ((UPPER_SIDE_WALK_Y_U <= pix_y) && (pix_y <= UPPER_SIDE_WALK_Y_B))||
                    ((MID_SIDE_WALK_Y_U <= pix_y)   && (pix_y <= MID_SIDE_WALK_Y_B))|| 
                    ((BTM_SIDE_WALK_Y_U <= pix_y)   && (pix_y <= BTM_SIDE_WALK_Y_B));
   // side rgb output
   assign side_rgb = 3'b011; // magneta

   //--------------------------------------------
   // cars ( to be edited later)
   //--------------------------------------------
   // boundary
   // for going from left to right
   assign car_x_l = car_x_reg_r;
   assign car_x_r = car_x_l + CAR_X_SIZE - 1;
   //2nd car
   assign car1_x_l = car_x_r + 200;
   assign car1_x_r = car1_x_l + CAR_X_SIZE - 1;
   //3rd car
   assign car2_x_l = car1_x_r + 150;
   assign car2_x_r = car2_x_l + CAR_X_SIZE - 1;
	//4th car
	assign car6_x_l = car2_x_r + 170;
   assign car6_x_r = car6_x_l + CAR_X_SIZE - 1;
   //for going from right to left
   assign car3_x_l = car_x_reg_l;
   assign car3_x_r = car3_x_l - CAR_X_SIZE + 1;
   //2nd car
   assign car4_x_l = car3_x_r - 140;
   assign car4_x_r = car4_x_l - CAR_X_SIZE + 1;
   //3rd car
   assign car5_x_l = car4_x_r - 190;
   assign car5_x_r = car5_x_l - CAR_X_SIZE + 1;
   // 4th car
   assign car7_x_l = car5_x_r - 180;
   assign car7_x_r = car7_x_l - CAR_X_SIZE + 1;
	// pixel within car
   assign car_on =
				// FIRST ROW & 3RD ROW
				( 
					( 	
						((car_x_l<=pix_x)  && (pix_x<=car_x_r)) 	||
					 	((car1_x_l<=pix_x) && (pix_x<=car1_x_r)) 	||
						((car6_x_l<=pix_x) && (pix_x<=car6_x_r)) 	||
					 	((car2_x_l<=pix_x) && (pix_x<=car2_x_r)) 
				   	)
					&&
                	(
						((CAR1_Y_T<=pix_y) && (pix_y<=CAR1_Y_B)) 	||
						((CAR3_Y_T<=pix_y) && (pix_y<=CAR3_Y_B))
					)	
				)
				///
				|| 
				
				// SECOND ROW & 4TH
				( 
					( 	((car3_x_l>=pix_x) && (pix_x>=car3_x_r)) 	||
					 	((car4_x_l>=pix_x) && (pix_x>=car4_x_r)) 	||
						((car7_x_l>=pix_x) && (pix_x>=car7_x_r)) 	||
					 	((car5_x_l>=pix_x) && (pix_x>=car5_x_r)) 
				   	)
					&&
                	(
						((CAR2_Y_T<=pix_y) && (pix_y<=CAR2_Y_B)) 	||
						((CAR4_Y_T<=pix_y) && (pix_y<=CAR4_Y_B))
					)	
				);
				
   // bar rgb output
   assign car_rgb = 3'b100; // red
   //new car x-position
  always @*
    begin
      car_x_next_r = car_x_reg_r; // no move
	  car_x_next_l = car_x_reg_l; 
      if (gra_still) // initial position of the cars
        begin
			car_x_next_r =  100;
			car_x_next_l = 600;
		end 
      else if (refr_tick)
		begin
          car_x_next_r = car_x_reg_r + CAR_V; // to right
		  car_x_next_l = car_x_reg_l - CAR_V; // to left
		end
    end 

    //==========================================
    // street bars 
    //====================================================================================================
    // pixel within bars
    assign bar_on = (( BAR1_Y_T <= pix_y && pix_y <= BAR1_Y_B)||(BAR2_Y_T <= pix_y && pix_y <= BAR2_Y_B)) &&
                    (( BAR_X_1 <= pix_x && pix_x <=BAR_X_2 )||(BAR_X_3<= pix_x && pix_x <=BAR_X_4) ||
                     ( BAR_X_5 <= pix_x && pix_x <=BAR_X_6 )||( BAR_X_7 <= pix_x && pix_x <=BAR_X_8)||
                     ( BAR_X_9 <= pix_x && pix_x <=BAR_X_10) ||(BAR_X_11<= pix_x && pix_x <=BAR_X_12 )||
                     ( BAR_X_13<= pix_x)) ;
    // street bars rgb output
    assign bar_rgb = 3'b111; // white
   //======================================================================================================
   //--------------------------------------------
   // square frog
   //--------------------------------------------
   // boundary
   assign frog_x_l = frog_x_reg;
   assign frog_y_t = frog_y_reg;
   assign frog_x_r = frog_x_l + FROG_SIZE - 1;
   assign frog_y_b = frog_y_t + FROG_SIZE - 1;
   // pixel within frog
   assign sq_frog_on =
            (frog_x_l<=pix_x) && (pix_x<=frog_x_r) &&
            (frog_y_t<=pix_y) && (pix_y<=frog_y_b);
   // map current pixel location to ROM addr/col
   assign rom_addr = pix_y[4:1] - frog_y_t[4:1];
   assign rom_col = pix_x[4:1] - frog_x_l[4:1];
   assign rom_bit = rom_data[rom_col];
   // pixel within frog
   assign rd_frog_on = sq_frog_on & rom_bit;
   // frog rgb output
   assign frog_rgb = 3'b001;   // green
  
   // new frog position
   assign frog_x_next = (gra_still|hit|miss) ? 10'd320 :
						      (refr_tick)			 ?
                         frog_x_reg + x_delta_reg :
						       frog_x_reg;
                        
   assign frog_y_next = (gra_still|hit|miss) ? 10'd413 :
						      (refr_tick)			 ?
                        frog_y_reg + y_delta_reg  ://y_delta_reg 
                        frog_y_reg ;
   // new frog velocity
   always @*   
   begin
    ///////////////////////////////
    // horizontal motion///////////
    if ((motion_cmd[0]) && (~ gra_still) && (~ hit)) //during game play
        x_delta_next= FROG_V_P;
    else if ((motion_cmd[2])&&(~ gra_still) && (~ hit))// during gameplay
        x_delta_next= FROG_V_N;
    else
        x_delta_next= 0;
    // vertical motion//////////////
    if ((motion_cmd[1]) && (~ gra_still)  && (~ hit))// during gameplay
        y_delta_next= FROG_V_P;
    else if ((motion_cmd[3]) && (~ gra_still) && (~ hit))// during gameplay
        y_delta_next= FROG_V_N;
    else
        y_delta_next= 0;
  end
  
    ////////////////////////////////   
   
   // digital circuit for hit and miss
   always@*
    begin
      hit = 1'b0;
      miss= 1'b0;
      // if the frog reached the upped side of the street
      if ( frog_y_b < UPPER_SIDE_WALK_Y_B - 10)
      		  hit = 1'b1;
     //if the frog hit the incoming cars
     if ( rd_frog_on && car_on)
			 miss = 1'b1;
        
   
    end
     
   //--------------------------------------------
   // rgb multiplexing circuit
   //--------------------------------------------
   always @* 
      if (rd_frog_on)
         graph_rgb = frog_rgb;
      else if (car_on)
         graph_rgb = (  ((car3_x_l - 26>=pix_x) && (pix_x>=car3_x_r+ 26)) 	||
					 	((car4_x_l- 26>=pix_x) && (pix_x>=car4_x_r+ 26)) 	||
						((car7_x_l- 26>=pix_x) && (pix_x>=car7_x_r+ 26)) 	||
					 	((car5_x_l- 26>=pix_x) && (pix_x>=car5_x_r+ 26))    ||
					    ((car_x_l + 26 <=pix_x)  && (pix_x<=car_x_r  - 26)) 	||
					 	((car1_x_l + 26<=pix_x) && (pix_x<=car1_x_r - 26)) 	||
						((car6_x_l + 26<=pix_x) && (pix_x<=car6_x_r- 26)) 	||
					 	((car2_x_l + 26<=pix_x) && (pix_x<=car2_x_r- 26)) 
					)
						? 3'b010:car_rgb; 
      else if (bar_on)
         graph_rgb = bar_rgb;
      else if (side_on)
           graph_rgb = side_rgb;
      else
            graph_rgb = 3'b000; // black background
   // new graphic_on signal
   assign graph_on = side_on | bar_on | rd_frog_on | car_on ;

endmodule 
