/*++
Abstract:
    LTE DFT Top Level
    Support 12*2^a*3^b*5^c point DFT and 
    16,32,64,128,256,512,1024,2048 point FFT
--*/

`include "macros.v"
`include "fixed_point.v"

module dft(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i,
  data_imag_i,
  trans_len_i,
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
  output block_sync_o;
  output data_val_o;
  output signed [`FFT_OUT_WIDTH-1:0] data_real_o;
  output signed [`FFT_OUT_WIDTH-1:0] data_imag_o;
  output [11:0] trans_len_o;
  output [10:0] data_index_o;
  
  //Local signals
  reg  [3:0]  ldn_rg;
  reg  [11:0] trans_len;
  reg    block_sync_z1;
  reg    data_val_z1;
  reg signed [`FFT_IN_WIDTH-1:0] data_real_z1;
  reg signed [`FFT_IN_WIDTH-1:0] data_imag_z1;
  
  //Glue logics
  always @(posedge clk_sys) begin
    block_sync_z1 <= block_sync_i;
    data_val_z1   <= data_val_i;
    data_real_z1  <= data_real_i;
    data_imag_z1  <= data_imag_i;	
  end
  
  always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)
    	trans_len <= 0;
    else if(block_sync_i)
    	trans_len <= trans_len_i;

	always @(posedge clk_sys or negedge rst_sys_n) begin
		if(!rst_sys_n)
		  ldn_rg <= 0;
		else if(block_sync_i)
	    case(trans_len_i)
	    	//2^n-point FFT
	    	12'd16    : ldn_rg <= 4;
	    	12'd32    : ldn_rg <= 5;
	    	12'd64    : ldn_rg <= 6;
	    	12'd128   : ldn_rg <= 7;
	    	12'd256   : ldn_rg <= 8;
	    	12'd512   : ldn_rg <= 9;
	    	12'd1024  : ldn_rg <= 10;
	    	12'd2048  : ldn_rg <= 11;
	    	//12*2^a*3^b*5^c-point DFT
	      12'd12    : ldn_rg <= 4;
	      12'd24    : ldn_rg <= 5;
	      12'd36    : ldn_rg <= 6;
        12'd48    : ldn_rg <= 6;
        12'd60    : ldn_rg <= 7;
        12'd72    : ldn_rg <= 7;
        12'd96    : ldn_rg <= 7;
        12'd108   : ldn_rg <= 8;
        12'd120   : ldn_rg <= 8;
        12'd144   : ldn_rg <= 8;
        12'd180   : ldn_rg <= 8;
        12'd192   : ldn_rg <= 8;
        12'd216   : ldn_rg <= 9;
        12'd240   : ldn_rg <= 9;
        12'd288   : ldn_rg <= 9;
        12'd300   : ldn_rg <= 9;
        12'd324   : ldn_rg <= 9;
        12'd360   : ldn_rg <= 9;
        12'd384   : ldn_rg <= 9;
        12'd432   : ldn_rg <= 10;
        12'd480   : ldn_rg <= 10;
        12'd540   : ldn_rg <= 10;
        12'd576   : ldn_rg <= 10;
        12'd600   : ldn_rg <= 10;
        12'd648   : ldn_rg <= 10;
        12'd720   : ldn_rg <= 10;
        12'd768   : ldn_rg <= 10;
        12'd864   : ldn_rg <= 11;
        12'd900   : ldn_rg <= 11;
        12'd960   : ldn_rg <= 11;
        12'd972   : ldn_rg <= 11;
        12'd1080  : ldn_rg <= 11;
        12'd1152  : ldn_rg <= 11;
        12'd1200  : ldn_rg <= 11;
        12'd1296  : ldn_rg <= 11;
        12'd1536  : ldn_rg <= 11;
        default   : ldn_rg <= 0;
      endcase
  end  
  
  wire pre_bypass;
  wire pre_block_sync;
  wire pre_data_val;
  wire signed [`FFT_IN_WIDTH-1:0] pre_data_real;
  wire signed [`FFT_IN_WIDTH-1:0] pre_data_imag;
  
  assign pre_bypass = (trans_len == 12'd16)||(trans_len == 12'd32)||(trans_len == 12'd64)||(trans_len == 12'd128)
                     ||(trans_len == 12'd256)||(trans_len == 12'd512)||(trans_len == 12'd1024)||(trans_len == 12'd2048);
  
  preproc preproc(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n), 
    .block_sync_i   (block_sync_z1&(~pre_bypass)), 
    .data_val_i     (data_val_z1&(~pre_bypass)), 
    .data_real_i    (data_real_z1),
    .data_imag_i    (data_imag_z1),
    .ldn_rg_i       (ldn_rg),  
    .trans_len_i    (trans_len[10:0]),  
  	.block_sync_o   (pre_block_sync),
  	.data_val_o     (pre_data_val),
  	.data_real_o    (pre_data_real),
  	.data_imag_o    (pre_data_imag)
    );
  
  reg  mux_block_sync;
  reg  mux_data_val;
  reg  signed [`FFT_IN_WIDTH-1:0] mux_data_real;
  reg  signed [`FFT_IN_WIDTH-1:0] mux_data_imag;
  wire fft_block_sync;
  wire fft_data_val;
  wire signed [`FFT_OUT_WIDTH-1:0] fft_data_real;
  wire signed [`FFT_OUT_WIDTH-1:0] fft_data_imag;   
  //wire [3:0] fft_ldn_rg;
  
  //always @(posedge clk_sys or negedge rst_sys_n) begin
  //	if(!rst_sys_n) begin
  //		mux_block_sync  <= 0;
  //		mux_data_val    <= 0;
  //		mux_data_real   <= 0;
  //		mux_data_imag   <= 0;
  //	end
  //	else begin   
  always @(*) begin
  	if(pre_bypass) begin
  		mux_block_sync <= block_sync_z1;
  		mux_data_val   <= data_val_z1;
  		mux_data_real  <= data_real_z1;
  		mux_data_imag  <= data_imag_z1;
  	end
  	else begin
  		mux_block_sync <= pre_block_sync;
  		mux_data_val   <= pre_data_val;
  		mux_data_real  <= pre_data_real;
  		mux_data_imag  <= pre_data_imag;  	
  	end	
  end
  
  fft fft(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n), 
    .block_sync_i   (mux_block_sync), 
    .data_val_i     (mux_data_val), 
    .data_real_i    (mux_data_real),
    .data_imag_i    (mux_data_imag),
    .ldn_rg_i       (ldn_rg),
    .block_sync_o   (fft_block_sync), 
    .data_val_o     (fft_data_val), 
    .data_real_o    (fft_data_real), 
    .data_imag_o    (fft_data_imag)
    //.ldn_rg_o       (fft_ldn_rg)
    );
  
  //reg  [10:0] fft_in_cnt;
  //wire [10:0] fft_in_cnt_p1;
  //
  //always @(posedge clk_sys or negedge rst_sys_n)
  //  if(!rst_sys_n)
  //  	fft_in_cnt <= 0;
  //  else if(mux_data_val)
  //  	fft_in_cnt <= fft_in_cnt_p1;
  //
  //assign fft_in_cnt_p1 = (mux_block_sync) ? 0 : fft_in_cnt + 1;
   
  
  postproc postproc(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n), 
    .block_sync_i   (fft_block_sync), 
    .data_val_i     (fft_data_val), 
    .data_real_i    (fft_data_real),
    .data_imag_i    (fft_data_imag),
    .ldn_rg_i       (ldn_rg),
    .trans_len_i    (trans_len),  
    .block_sync_o   (block_sync_o), 
    .data_val_o     (data_val_o), 
    .data_real_o    (data_real_o), 
    .data_imag_o    (data_imag_o),
    .trans_len_o    (trans_len_o),
    .data_index_o   (data_index_o)
    );
      
endmodule
