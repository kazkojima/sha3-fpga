// SHA3 message digest for limited inputs

module sha3 #(parameter MDLEN = 256, N = 128)
  (input clk,
   input rst,
   input [N-1:0] md_in,
   output [MDLEN-1:0] md_out,
   input req_valid,
   output reg req_ready,
   output reg req_busy,
   output reg res_valid,
   input res_ready);

   reg [3:0] state;
   localparam S_IDLE = 2;
   localparam S_START = 3;
   localparam S_WAITACK = 4;
   localparam S_WAITRDY = 5;
   localparam S_POST = 6;
   localparam S_CLEANUP = 7;

   wire [511:0] out, out_rev;
   wire [MDLEN-1:0] md_out;
   reg f_rst;
   wire [575:0] f_in;
   wire [575:0] f_in_rev;
   reg f_in_ready;

   wire f_ack;
   wire [1599:0] f_out;
   wire f_out_ready;

   assign f_in_rev[575:575-(N-1)] = md_in;
   assign f_in_rev[575-N:575-N-7] = 8'h06;
   assign f_in_rev[575-N-8:0] = 0;
   assign out_rev = f_out[1599:1599-511];
   assign md_out = out[511:511-(MDLEN-1)];

   // Reorder bytes
`define low_pos(w,b)      ((w)*64 + (b)*8)
`define low_pos2(w,b)     `low_pos(w,7-b)
`define high_pos(w,b)     (`low_pos(w,b) + 7)
`define high_pos2(w,b)    (`low_pos2(w,b) + 7)

   genvar w, b;

   generate
      for(w=0; w<8; w=w+1)
        begin : L0
           for(b=0; b<8; b=b+1)
             begin : L1
		assign out[`high_pos(w,b):`low_pos(w,b)] = out_rev[`high_pos2(w,b):`low_pos2(w,b)];
             end
        end
   endgenerate

   generate
      for(w=0; w<9; w=w+1)
        begin : L2
           for(b=0; b<8; b=b+1)
             begin : L3
		assign f_in[`high_pos(w,b):`low_pos(w,b)] = f_in_rev[`high_pos2(w,b):`low_pos2(w,b)];
             end
        end
   endgenerate

   // Keccak
   f_permutation #(.MDLEN(MDLEN)) fperm (
        .clk(clk),
        .reset(f_rst),
        .in(f_in),
        .in_ready(f_in_ready),
        .ack(f_ack),
        .out(f_out),
        .out_ready(f_out_ready)
    );
 
   always @(posedge clk) begin
      if (rst) begin
         state <= S_IDLE;
         req_ready <= 0;
         res_valid <= 0;
         req_busy <= 0;
	 f_rst <= 1;
      end
      else if (state == S_IDLE) begin
         if (req_valid == 1'b1) begin
            req_ready <= 1;
            req_busy <= 1;
            state <= S_START;
	 end
      end
      else if (state == S_START) begin
         req_ready <= 0;
	 f_rst <= 0;
	 f_in_ready <= 1;
         state <= S_WAITACK;
      end
      else if (state == S_WAITACK) begin
	 if (f_ack) begin
	    f_in_ready <= 0;
	    state <= S_WAITRDY;
	 end
      end
      else if (state == S_WAITRDY) begin
	 f_in_ready <= 0;
	 if (f_out_ready) begin
	    state <= S_POST;
	 end
      end
      else if (state == S_POST) begin
	 res_valid <= 1;
	 state <= S_CLEANUP;
      end
      else if (state == S_CLEANUP) begin
         if (res_ready) begin
            res_valid <= 0;
	    f_rst <= 1;
            state <= S_IDLE;
         end
      end
   end // always @ (posedge clk)

`undef low_pos
`undef low_pos2
`undef high_pos
`undef high_pos2

endmodule
