/*++
Abstract:
  pipeline fft radix-4 unit 4, RAM for stage one
--*/

`include "macros.v"
`include "fixed_point.v"

module r4u4_one_ram(
  clk_sys,
  rd_addr,
  rd_data,   //registered output
  wr_en,     //active low
  wr_addr,
  wr_data    
);
  input clk_sys;
  input  [9:0] rd_addr;
  output [`MAN_WIDTH+`MAN_WIDTH+`EXP_WIDTH-1:0] rd_data;
  input wr_en;
  input [9:0] wr_addr;
  input [`MAN_WIDTH+`MAN_WIDTH+`EXP_WIDTH-1:0] wr_data;

`ifdef ASIC
  ram_asic_one_r4u4 ram_asic_one_r4u4(
	  .clk_sys        (clk_sys),
	  .rd_addr        (rd_addr),
	  .rd_data        (rd_data),
	  .wr_en          (wr_en),     
	  .wr_addr        (wr_addr),
	  .wr_data        (wr_data)    
  );
`elsif FPGA
  ram_fpga_one_r4u4 ram_fpga_one_r4u4(
	  .clk_sys        (clk_sys),
	  .rd_addr        (rd_addr),
	  .rd_data        (rd_data),
	  .wr_en          (wr_en),  
	  .wr_addr        (wr_addr),
	  .wr_data        (wr_data) 
  );
`else   //simulation
  reg  [`MAN_WIDTH+`MAN_WIDTH+`EXP_WIDTH-1:0] ram_mem[1023:0];
  reg  [`MAN_WIDTH+`MAN_WIDTH+`EXP_WIDTH-1:0] rd_data;  
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
