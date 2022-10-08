/*++
Abstract:
    pre-processing unit, top level
--*/

`include "macros.v"
`include "fixed_point.v"

module preproc(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i,
  data_imag_i,
  ldn_rg_i,  
  trans_len_i,  
	block_sync_o,
	data_val_o,
	data_real_o,
	data_imag_o
  );
  parameter DATA_WIDTH = 2*`FFT_IN_WIDTH;
  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input    data_val_i;
  input signed [`FFT_IN_WIDTH-1:0] data_real_i;
  input signed [`FFT_IN_WIDTH-1:0] data_imag_i;
  input [3:0]   ldn_rg_i;  
  input [10:0]  trans_len_i;
	output  block_sync_o;
	output  data_val_o;
	output signed [`FFT_IN_WIDTH-1:0] data_real_o;
	output signed [`FFT_IN_WIDTH-1:0] data_imag_o;
  
  //Local signals
  wire  [DATA_WIDTH-1:0] dout;
  wire  re;
  wire  empty;
  wire  almost_empty;
 
  

  cyc_recon cyc_recon(
    .clk_sys          (clk_sys), 
    .rst_sys_n        (rst_sys_n), 
    .block_sync_i     (block_sync_i), 
    .data_val_i       (data_val_i), 
    .data_real_i      (data_real_i),
    .data_imag_i      (data_imag_i),
    .trans_len_i      (trans_len_i),
    .re_i             (re),
    .dout_o           (dout), 
    .empty_o          (empty), 
    .almost_empty_o   (almost_empty)
    );

  src src(
    .clk_sys          (clk_sys), 
    .rst_sys_n        (rst_sys_n), 
    .block_sync_i     (block_sync_i), 
    .ldn_rg_i         (ldn_rg_i),
    .trans_len_i      (trans_len_i),
    .din_i            (dout), 
  	.empty_i          (empty), 
  	.almost_empty_i   (almost_empty),
  	.re_o             (re),
  	.block_sync_o     (block_sync_o),
  	.data_val_o       (data_val_o),
  	.data_real_o      (data_real_o),
  	.data_imag_o      (data_imag_o)
    );

  //dump test data
  //integer  test_file;
  //always @(posedge clk_sys) begin
  //  if(data_val_o == 1'b1)
  //    $fdisplay(test_file,"%d      %d", data_real_o, data_imag_o);    
  //end  
  //
  //initial
  //  test_file = $fopen(`TEST_FILE);
  
endmodule
