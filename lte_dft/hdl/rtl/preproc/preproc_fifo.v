/*++
Abstract:
    Synchronous FIFO in pre-processing unit
    deep: 4
--*/

`include "macros.v"
`include "fixed_point.v"

module preproc_fifo(
  clk_sys, 
  rst_sys_n,    //active low, asynchronous reset 
  clr_i,        //synchronous clear, active high
  we_i,         //write enable, active high
  din_i, 
  re_i,         //read enable, active high 
   
  dout_o, 
	full_o, 
	empty_o, 
	almost_full_o,
	almost_empty_o
);
parameter DATA_WIDTH = 2*`FFT_IN_WIDTH;
input     clk_sys;
input     rst_sys_n;
input     clr_i;
input     we_i;
input     [DATA_WIDTH-1:0] din_i;
input     re_i;
output    [DATA_WIDTH-1:0] dout_o;
output    full_o;
output    empty_o;
output    almost_full_o;
output    almost_empty_o;

//
// Local Wires
//
reg [3:0] wptr;
reg [3:0] rptr;

//
// Memory Block
//

reg [DATA_WIDTH-1:0] fifo_mem[7:0];

always @(posedge clk_sys or negedge rst_sys_n) begin
  if (!rst_sys_n) begin
  	fifo_mem[0] <= 0;
  	fifo_mem[1] <= 0;
  	fifo_mem[2] <= 0;
  	fifo_mem[3] <= 0;
  	fifo_mem[4] <= 0;
  	fifo_mem[5] <= 0;
  	fifo_mem[6] <= 0;
  	fifo_mem[7] <= 0;  	
  end
  else begin
  	if (we_i && (!full_o))
  	  fifo_mem[wptr[2:0]] <= din_i;
	end
end

assign dout_o = fifo_mem[rptr[2:0]];

//
// Misc Logic
//

always @(posedge clk_sys or negedge rst_sys_n)
  if(!rst_sys_n)
	  wptr <= 4'b0;
  else if(clr_i)
    wptr <= 4'b0;
  else if(we_i && (!full_o))
  	wptr <= wptr + 4'b1;

always @(posedge clk_sys or negedge rst_sys_n)
  if(!rst_sys_n)	
  	rptr <= 4'b0;
  else if(clr_i)
  	rptr <= 4'b0;
  else if(re_i && (!empty_o))
  	rptr <= rptr + 4'b1;

//
// Combinatorial Full & Empty Flags
//

assign empty_o = (wptr[3:0] == rptr[3:0]);
assign full_o  = ((wptr[2:0] == rptr[2:0]) && (wptr[3] != rptr[3]));

wire [3:0] wptr_pl1 = wptr + 4'b1;
wire [3:0] rptr_pl1 = rptr + 4'b1;

assign almost_empty_o = (wptr[3:0] == rptr_pl1[3:0]);
assign almost_full_o  = ((wptr_pl1[2:0] == rptr[2:0]) && (wptr_pl1[3] != rptr[3]));

endmodule


