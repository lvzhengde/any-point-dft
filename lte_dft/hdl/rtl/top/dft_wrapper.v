/*++
Abstract:
    LTE DFT Top Level
    Support 12*2^a*3^b*5^c point DFT and 
    16,32,64,128,256,512,1024,2048 point FFT
--*/

`include "macros.v"
`include "fixed_point.v"

module dft_wrapper(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i,
  data_imag_i,
  trans_len_i,
  inv_en_i,
  
  block_sync_o, 
  data_val_o, 
  data_real_o, 
  data_imag_o,
  trans_len_o,
  data_index_o
  );

  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input    data_val_i;
  input signed [`FFT_IN_WIDTH-1:0] data_real_i;
  input signed [`FFT_IN_WIDTH-1:0] data_imag_i;
  input [11:0]  trans_len_i;
  input    inv_en_i;    // 0: DFT; 1: iDFT
  output block_sync_o;
  output data_val_o;
  output signed [`FFT_OUT_WIDTH-1:0] data_real_o;
  output signed [`FFT_OUT_WIDTH-1:0] data_imag_o;
  output [11:0] trans_len_o;
  output [10:0] data_index_o;
    
  wire signed [`FFT_IN_WIDTH-1:0]  data_imag_in;   
  wire signed [`FFT_OUT_WIDTH-1:0] data_imag_out;
  
  reg  inv_en_i_z1;
  wire inv_enalbe_in;
  
  always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)
    	inv_en_i_z1 <= 0;
    else if(block_sync_i == 1'b1)
    	inv_en_i_z1 <= inv_en_i;
  
  assign inv_enable_in = (inv_en_i == 1'b1 && block_sync_i == 1'b1) || (inv_en_i_z1 == 1'b1); 
  
  assign data_imag_in = (inv_enable_in == 1'b0) ? data_imag_i : (-data_imag_i); 
  
  dft dft(
    .clk_sys        (clk_sys       ), 
    .rst_sys_n      (rst_sys_n     ), 
    .block_sync_i   (block_sync_i  ), 
    .data_val_i     (data_val_i    ),   
    .data_real_i    (data_real_i   ),
    .data_imag_i    (data_imag_in  ),
    .trans_len_i    (trans_len_i   ),
    .block_sync_o   (block_sync_o  ), 
    .data_val_o     (data_val_o    ), 
    .data_real_o    (data_real_o   ), 
    .data_imag_o    (data_imag_out ),
    .trans_len_o    (trans_len_o   ),
    .data_index_o   (data_index_o  )
    );
 
  reg  [11:0] sym_cnt_in;
  reg  inv_en_o; 
  reg  inv_en_o_z1;
  wire inv_enable_out;
  
  always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)
    	sym_cnt_in <= 0;
    else if(block_sync_i == 1'b1)
    	sym_cnt_in <= 0;
    else if (data_val_i == 1'b1)
    	sym_cnt_in <= sym_cnt_in + 1;
  
  always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)
    	inv_en_o <= 0;
    else if(sym_cnt_in == trans_len_i-2)
    	inv_en_o <= inv_en_i_z1;
    	
  always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)
    	inv_en_o_z1 <= 0;
    else if(block_sync_o == 1'b1)
    	inv_en_o_z1 <= inv_en_o;
  
  assign inv_enable_out = (inv_en_o == 1'b1 && block_sync_o == 1'b1) || (inv_en_o_z1 == 1'b1);
  
  assign data_imag_o = (inv_enable_out == 1'b0) ? data_imag_out : (-data_imag_out);

endmodule
