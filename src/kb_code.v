
module kb_code
   #(parameter W_SIZE = 2)  // 2^W_SIZE words in FIFO
   (
    input wire clk, reset,
    input wire ps2d, ps2c, //rd_key_code,
    output wire [7:0] key_code
    //output wire kb_buf_empty
   );

   // constant declaration
   localparam BRK = 8'hf0; // break code

   // symbolic state declaration
   localparam
      wait_brk = 2'b00,
      get_code = 2'b01,
	  hold_on  = 2'b11;
   // signal declaration
   reg state_reg, state_next;
   wire [7:0] scan_out;
   reg got_code_tick;
   wire scan_done_tick;
   reg [4:0] n_reg;
   reg [4:0] n_next;
   //
   reg [7:0] key_code_ps;
   reg acknowledged;
   // body
   //====================================================
   // instantiation
   //====================================================
   // instantiate ps2 receiver
   ps2_rx ps2_rx_unit
      (.clk(clk), .reset(reset), .rx_en(1'b1),
       .ps2d(ps2d), .ps2c(ps2c),
       .rx_done_tick(scan_done_tick), .dout(scan_out),.acknowledged(acknowledged));

   // instantiate fifo buffer
   //fifo #(.B(8), .W(W_SIZE)) fifo_key_unit
   //  (.clk(clk), .reset(reset), .rd(rd_key_code),
   //   .wr(got_code_tick), .w_data(scan_out),
    //  .empty(kb_buf_empty), .full(),
    //  .r_data());//key_code_ps//

   //=======================================================
   // FSM to get the scan code after F0 received
   //=======================================================
   // state registers
   always @(posedge clk, posedge reset)
      if (reset)
		begin
         state_reg <= wait_brk;
		 n_reg <= 0;
		end
      else
		begin
         state_reg <= state_next;
	     n_reg <= n_next;
	    end
	
	
	// output logic for key code
	assign key_code = scan_out;//(state_reg == get_code )? key_code_ps: 8'h00 ;
  
	// next-state logic
   always @*
   begin
      got_code_tick = 1'b0;
      state_next = state_reg;
      acknowledged = 1'b0;
	  n_next = n_reg;
      case (state_reg)
         wait_brk:  // wait for F0 of break code
             
            if (scan_done_tick==1'b1 && scan_out==BRK)
               state_next = get_code;
         get_code:  // get the following scan code
            if (scan_done_tick)
               begin
				  n_next = 4'h01;
                  got_code_tick =1'b1;
				  key_code_ps = scan_out;
				  acknowledged = 1'b1;
                  state_next = wait_brk;
               end
		
      endcase
   end

endmodule
