
module frogger_top
   (
    input wire clk, reset,
    input wire ps2c,ps2d,
    output wire hsync, vsync,
    output wire [2:0] rgb,
	//FOR DEGB
	output wire [3:0]motion_cmd
   );

   // symbolic state declaration
   localparam  [1:0]
      newgame = 2'b00,
      play    = 2'b01,
      newfrog = 2'b10,
      over    = 2'b11;

   // signal declaration
   reg [1:0] state_reg, state_next;
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick, graph_on, hit, miss;
   wire [3:0] text_on;
   wire [2:0] graph_rgb, text_rgb;
   reg [2:0] rgb_reg, rgb_next;
   wire [3:0] dig0, dig1;
   reg gra_still, d_inc, d_clr, timer_start;
   wire timer_tick, timer_up;
   reg [1:0] frog_reg, frog_next;
	wire refr_tick;
	reg win_on;
	//wire R,G,B;
	wire G;
   //wire [3:0] motion_cmd;

   //=======================================================
   // instantiation
   //=======================================================
   // instantiate video synchronization unit
   hvsync_generator vsync_unit
		(.clk(clk), .vga_h_sync(hsync), 
			.vga_v_sync(vsync), 
			.inDisplayArea(video_on), 
			.CounterX(pixel_x), .CounterY(pixel_y));
	//vga_sync vsync_unit
      //(.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
       //.video_on(video_on), .p_tick(pixel_tick),
       //.pixel_x(pixel_x), .pixel_y(pixel_y));
   // instantiate text module
   frogger_text text_unit
      (.clk(clk),
       .pix_x(pixel_x), .pix_y(pixel_y),
       .dig0(dig0), .dig1(dig1), .frog(frog_reg),
       .text_on(text_on), .text_rgb(text_rgb));
   // instantiate graph module
   frogger_graph graph_unit
      (.clk(clk), .reset(reset), .motion_cmd(motion_cmd),
       .pix_x(pixel_x), .pix_y(pixel_y),
       .gra_still(gra_still), .hit(hit), .miss(miss),
       .graph_on(graph_on), .graph_rgb(graph_rgb),.refr_tick(refr_tick));
   // instantiate 2 sec timer
   // 60 Hz tick
   assign timer_tick = (pixel_x==0) && (pixel_y==0);
   timer timer_unit
      (.clk(clk), .reset(reset), .timer_tick(timer_tick),
       .timer_start(timer_start), .timer_up(timer_up));
   // instantiate 2-digit decade counter
   m100_counter counter_unit
      (.clk(clk), .reset(reset), .d_inc(d_inc), .d_clr(d_clr),
       .dig0(dig0), .dig1(dig1));
   // instantiate keyboard command router
   keyboard_cmd key_unit
    (.clk(clk), .reset(reset),.ps2d(ps2d), .ps2c(ps2c),.motion_cmd(motion_cmd),.refr_tick(refr_tick));
   // Instantiate roms
  // R_rom r_rom_unit(.clk(clk),.pix_x(pixel_x),.pix_y(pixel_y),.R(R));
   G_rom g_rom_unit(.clk(clk),.pix_x(pixel_x),.pix_y(pixel_y),.G(G));
   //B_rom b_rom_unit(.clk(clk),.pix_x(pixel_x),.pix_y(pixel_y),.B(B)); 
   //=======================================================
   // FSMD
   //=======================================================
   // FSMD state & data registers
    always @(posedge clk, posedge reset)
       if (reset)
          begin
             state_reg <= newgame;
             frog_reg <= 0;
             rgb_reg <= 0;
          end
       else
          begin
            state_reg <= state_next;
            frog_reg <= frog_next;
            //if (pixel_tick)
               rgb_reg <= rgb_next;
          end
   // FSMD next-state logic
   always @*
   begin
      gra_still = 1'b1;
      timer_start = 1'b0;
      d_inc = 1'b0;
      d_clr = 1'b0;
      win_on = 1'b0;
      state_next = state_reg;
      frog_next = frog_reg;
      case (state_reg)
         newgame:
            begin
               frog_next = 2'b11; // three frogs
               d_clr = 1'b1;      // clear score
               if (motion_cmd != 4'b0000)  // button pressed
                  begin
                     state_next = play;
                     frog_next = frog_reg - 1;
                  end
            end
         play:
           
              if (timer_up)
                 begin 
                  gra_still = 1'b0;  // animated screen
                  if (hit)
                     begin
                        d_inc = 1'b1;   // increment score
                        timer_start = 1'b1;
                        win_on = 1'b1;
                    end
                  else if (miss)
                     begin
                        if (frog_reg==0)
                           state_next = over;
                        else
                           state_next = newfrog;
                     	   timer_start = 1'b1;  // 2 sec timer
                     	   frog_next = frog_reg - 1;
                     end
            		end
				else
					win_on = 1'b1;
         newfrog:
			begin
			gra_still = 1'b1;  // stop screen
            // wait for 2 sec and until button pressed
            if (timer_up && (motion_cmd != 4'b0000))
                state_next = play;
			end
         over:
			begin
            gra_still = 1'b1;  // animated screen
			// wait for 2 sec to display game over
            if (timer_up)
                state_next = newgame;
			end
       endcase
    end
   //=======================================================
   // rgb multiplexing circuit
   //=======================================================
   always @*
      if (~video_on)
         rgb_next = "000"; // blank the edge/retrace
      else
         // display score, rule, or game over
         if (win_on)
               rgb_next = {1'b0,1'b0,G};
         else if (text_on[3] ||
               ((state_reg==newgame) && text_on[1]) || // rule
               ((state_reg==over) && text_on[0]))
            rgb_next = text_rgb;
         else if (graph_on)  // display graph
           rgb_next = graph_rgb;
         else if (text_on[2]) // display logo
           rgb_next = text_rgb;
         else
           rgb_next = 3'b000; // yellow background
   // output
   assign rgb = rgb_reg;
endmodule
