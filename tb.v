// testbench for SHA3 message digest for limited inputs

`timescale 1 ns / 1 ps

`include "./sha3.v"

`define MDLEN 256
`define ILEN 344

module testbench;
   reg clk;

   always #5 clk = (clk === 1'b0);

   initial
     begin
        state = 0;
	rst = 1'b1;
	count = 0;
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        repeat (4) begin
           repeat (100) @(posedge clk);
           $display("+100 cycles");
        end
        $finish;
     end

   reg [3:0] state;
   reg rst;
   reg [15:0] count;

   wire [`MDLEN-1:0] sha3_out;
   wire req_ready, req_busy, res_valid;
   reg res_ready;

   sha3 #(.MDLEN(`MDLEN), .N(`ILEN)) sha3_
   (.clk(clk), .rst(rst),
    .md_in(344'h54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f67),
    .md_out(sha3_out),
    .req_valid(1'b1),
    .req_ready(req_ready),
    .req_busy(req_busy),
    .res_valid(res_valid),
    .res_ready(res_ready));

   always @(posedge clk) begin
      if (state > 3) begin
	 rst <= 0;
      end
      else begin
	 state <= state + 1;
      end
      if (!rst) begin
         if (res_valid & !res_ready) begin
            res_ready <= 1;
	    if (sha3_out == 256'h69070dda01975c8c120c3aada1b282394e7f032fa9cf32f4cb2259a0897dfc04) begin
	       count <= count + 1;
	       if (count == 0)
		 $display("Result OK");
	    end
	    state <= 4;
	 end
         else if (!res_valid) begin
            res_ready <= 0;
         end
      end // if (!rst)
      //$display($time,,,"state=%d rst=%d", state, rst);
   end // always @ (posedge clk)

endmodule // testbench
