/*++
Abstract:
  pipeline fft, RAM for bit reverse operation
--*/

`include "macros.v"
`include "fixed_point.v"

module bit_rev_ram(
  clk_sys,
  wr_en,     //active low
  wr_addr,
  wr_data,    //registered output  
  rd_addr,
  rd_data,
);
  parameter RAM_WIDTH = 2*`FFT_OUT_WIDTH;
  input clk_sys;
  input [10:0] rd_addr;
  output [RAM_WIDTH-1:0] rd_data;
  input wr_en;
  input [10:0] wr_addr;
  input [RAM_WIDTH-1:0] wr_data;

`ifdef ASIC
  ram_asic_bit_rev ram_asic_bit_rev(
	  .clk_sys        (clk_sys),
	  .wr_en          (wr_en),     
	  .wr_addr        (wr_addr),
	  .wr_data        (wr_data),    	  
	  .rd_addr        (rd_addr),
	  .rd_data        (rd_data)

  );
`elsif FPGA
  ram_fpga_bit_rev ram_fpga_bit_rev(
	  .clk_sys        (clk_sys),
	  .wr_en          (wr_en),  
	  .wr_addr        (wr_addr),
	  .wr_data        (wr_data), 	  
	  .rd_addr        (rd_addr),
	  .rd_data        (rd_data)
  );
`else   //simulation
  reg  [RAM_WIDTH-1:0] ram_mem[2047:0];
  reg  [RAM_WIDTH-1:0] rd_data; 
  //read operation
  always @(posedge clk_sys)
    rd_data <= ram_mem[rd_addr];
  
  //write operation
  always @(posedge clk_sys) begin
    if (!wr_en)
      ram_mem[wr_addr] <= wr_data;
  end
  
`endif

endmodule
