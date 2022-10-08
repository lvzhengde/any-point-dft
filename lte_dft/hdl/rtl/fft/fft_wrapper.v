/*++
Abstract:
    Radix2^2 FFT top level
--*/

`include "macros.v"
`include "fixed_point.v"

module fft_wrapper(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i,
  data_imag_i,
  ldn_rg_i,
  inv_en_i,     //0: FFT;  1: iFFT
  
  block_sync_o, 
  data_val_o, 
  data_real_o, 
  data_imag_o
  );

  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input    data_val_i;
  input signed [`FFT_IN_WIDTH-1:0] data_real_i;
  input signed [`FFT_IN_WIDTH-1:0] data_imag_i;
  input [3:0]  ldn_rg_i;
  input    inv_en_i;
  output   block_sync_o;
  output   data_val_o;
  output signed [`FFT_OUT_WIDTH-1:0] data_real_o;
  output signed [`FFT_OUT_WIDTH-1:0] data_imag_o;
  
  wire signed [`FFT_IN_WIDTH-1:0]  data_imag_in;   
  wire signed [`FFT_OUT_WIDTH-1:0] data_imag_out;
  
  assign data_imag_in = (inv_en_i == 1'b0) ? data_imag_i : (-data_imag_i); 
    
  fft fft(
    .clk_sys        (clk_sys       ), 
    .rst_sys_n      (rst_sys_n     ), 
    .block_sync_i   (block_sync_i  ), 
    .data_val_i     (data_val_i    ), 
    .data_real_i    (data_real_i   ),
    .data_imag_i    (data_imag_in  ),
    .ldn_rg_i       (ldn_rg_i      ),
    .block_sync_o   (block_sync_o  ), 
    .data_val_o     (data_val_o    ), 
    .data_real_o    (data_real_o   ), 
    .data_imag_o    (data_imag_out )
    );  
    
  assign data_imag_o = (inv_en_i == 1'b0) ? data_imag_out : (-data_imag_out);             

endmodule

