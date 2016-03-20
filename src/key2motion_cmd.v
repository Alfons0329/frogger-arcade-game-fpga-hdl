module key2motion
    //IO parameters
    (   input wire [7:0] key_code,
		input wire refr_tick,
        output reg  [3:0] motion_cmd
     );
     
     always@*
      case (key_code)
        8'h1d: motion_cmd=4'b1000;// for W : move up
        8'h1c: motion_cmd=4'b0100;//for A : move left
        8'h1b: motion_cmd=4'b0010;//for S : move down
        8'h23: motion_cmd=4'b0001;// for D: move right
        // its possible to add Pause/Resume option, Start New game 
        default: motion_cmd=4'b0000;
      endcase
    endmodule
    