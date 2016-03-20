
module keyboard_cmd
   (
    input wire clk, reset,
    input wire ps2d, ps2c,
    output wire [3:0] motion_cmd,
	input wire refr_tick
   );

   // signal declaration
   wire [7:0] key_code;
   //wire kb_not_empty, kb_buf_empty;

   // body
   // instantiate keyboard scan code circuit
   kb_code kb_code_unit
      (.clk(clk), .reset(reset), .ps2d(ps2d), .ps2c(ps2c)
       , .key_code(key_code)
     );
  //instantiate key 2 motion command
  key2motion key_motion_cmd_unit (.key_code(key_code),.motion_cmd(motion_cmd),.refr_tick(refr_tick));
  
   //assign kb_not_empty = ~kb_buf_empty;

endmodule