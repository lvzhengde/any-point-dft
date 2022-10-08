/*++
Abstract:
    data type conversion from fixed-point to semi-float
--*/

`include "macros.v"
`include "fixed_point.v"

module fixed2bfp(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i,
  data_imag_i, 
  block_sync_o, 
  data_val_o, 
  data_real_o, 
  data_imag_o, 
  data_exp_o
  );
  parameter MAX_INPUT = ((1 <<< (`FFT_IN_WIDTH-1))-1);
  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input    data_val_i;
  input signed [`FFT_IN_WIDTH-1:0] data_real_i;
  input signed [`FFT_IN_WIDTH-1:0] data_imag_i;
  output reg block_sync_o;
  output reg data_val_o;
  output reg signed [`MAN_WIDTH-1:0] data_real_o;
  output reg signed [`MAN_WIDTH-1:0] data_imag_o;
  output reg signed [`EXP_WIDTH-1:0] data_exp_o;
 
  reg signed [`MAN_WIDTH-1:0] data_real_out;
  reg signed [`MAN_WIDTH-1:0] data_imag_out;
  reg signed [`EXP_WIDTH-1:0] data_exp_out; 
  reg signed [`FFT_IN_WIDTH-1:0] abs_data_real;
  reg signed [`FFT_IN_WIDTH-1:0] abs_data_imag;
  reg signed [`FFT_IN_WIDTH-1:0] abs_max_value;
  reg signed [`FFT_IN_WIDTH-1:0] bits_index;
 
  reg signed [`FFT_IN_WIDTH-1:0] data_real;
  reg signed [`FFT_IN_WIDTH-1:0] data_imag;
  reg signed [`EXP_WIDTH-1:0] exponent;
  reg signed [5:0] lshift_count; 
  reg signed [5:0] cutbits;
  //pipeline stage 1     
  always @(*) begin : ActComb       
    integer i;
    reg stop_shift;
      
    //saturation protection of input data
    data_real = data_real_i;
    data_imag = data_imag_i;
    `SYMSAT(data_real, `FFT_IN_WIDTH);  
    `SYMSAT(data_imag, `FFT_IN_WIDTH);    
      
    //get maximum magnitude of input
    abs_data_real = (data_real>=0)?data_real:-data_real;
    abs_data_imag = (data_imag>=0)?data_imag:-data_imag;    
    abs_max_value = (abs_data_real >= abs_data_imag)?abs_data_real:abs_data_imag;
    
    //count shift operations
    bits_index = abs_max_value;
    lshift_count = 0;
    stop_shift = 0;
    for (i = `FFT_IN_WIDTH-2; i >= 0; i = i-1) begin
      if (bits_index[i] == 1) 
        stop_shift = 1;
      if (stop_shift == 0)
        lshift_count = lshift_count + 1;
    end
  end
  
  reg signed [5:0] lshift_count_z1; 
  reg block_sync_z1;
  reg data_val_z1;
  reg signed [`FFT_IN_WIDTH-1:0] data_real_z1;  
  reg signed [`FFT_IN_WIDTH-1:0] data_imag_z1;  
  always @(posedge clk_sys) begin
    lshift_count_z1 <= lshift_count; 
    block_sync_z1   <= block_sync_i;
    data_val_z1     <= data_val_i;
    data_real_z1    <= data_real_i;  
    data_imag_z1    <= data_imag_i;        
  end

  //pipeline stage 2
  reg signed [31:0] data_real_tmp; 
  reg signed [31:0] data_imag_tmp;    
  reg signed [31:0] data_real_tmp1; 
  reg signed [31:0] data_imag_tmp1;    
  //reg signed [31:0] temp1;     
  //reg signed [31:0] temp2;
  //reg signed [31:0] temp3; 
  //reg signed [31:0] temp4; 
  //reg signed [31:0] temp5; 
      
  always @(*) begin
    exponent = `FFT_IN_WIDTH - 1 - `FFT_IN_PTPOS - lshift_count_z1;
    data_real_tmp = data_real_z1 <<< lshift_count_z1;
    data_imag_tmp = data_imag_z1 <<< lshift_count_z1;
  
    cutbits = `FFT_IN_WIDTH - `MAN_WIDTH;
    if (cutbits > 0) begin
      //for debug purpose
      //temp1 = $signed({1'b0,(1<<(cutbits-1))-1});
      //temp2 = data_imag_tmp + temp1;
      //temp3 = temp2 >>> cutbits;
      //temp4 = data_imag_tmp + $signed({1'b0,(1<<(cutbits-1))-1});
      //temp5 = (data_imag_tmp + $signed({1'b0,(1<<(cutbits-1))-1})) >>> cutbits;
      
      
      //if (cutbits <= 0)                                                     
      //  data_real_tmp1 = data_real_tmp;                                                                
      //else                                                                   
      //  if (data_real_tmp >= 0) data_real_tmp1 = (data_real_tmp+$signed({1'b0,(1<<(cutbits-1))}))>>>cutbits;     
      //  else  data_real_tmp1 = (data_real_tmp+$signed({1'b0,(1<<(cutbits-1))-1}))>>>cutbits;                   

      //if (cutbits <= 0)                                                     
      //  data_imag_tmp1 = data_imag_tmp;                                                                
      //else                                                                   
      //  if (data_imag_tmp >= 0) data_imag_tmp1 = (data_imag_tmp+$signed({1'b0,(1<<(cutbits-1))}))>>>cutbits;     
      //  else  data_imag_tmp1 = (data_imag_tmp+$signed({1'b0,(1<<(cutbits-1))-1}))>>>cutbits;                   
      
      `SYMRND(data_real_tmp, data_real_tmp1, cutbits);
      `SYMRND(data_imag_tmp, data_imag_tmp1, cutbits);
    end
    else if (cutbits < 0) begin
      data_real_tmp1 = data_real_tmp <<< (-cutbits);
      data_imag_tmp1 = data_imag_tmp <<< (-cutbits);
    end
    
    //saturation
    `SYMSAT(data_real_tmp1, `MAN_WIDTH);  
    `SYMSAT(data_imag_tmp1, `MAN_WIDTH);        
    data_real_out = data_real_tmp1[`MAN_WIDTH-1:0];
    data_imag_out = data_imag_tmp1[`MAN_WIDTH-1:0];            
    data_exp_out  = exponent;
  end

  always @(posedge clk_sys or negedge rst_sys_n) begin : ActReg
    if (!rst_sys_n) begin
      block_sync_o <= 0;
      data_val_o   <= 0;
      data_real_o  <= 0;
      data_imag_o  <= 0;
      data_exp_o   <= 0;
    end
    else begin
      block_sync_o <= block_sync_z1;
      data_val_o   <= data_val_z1;
      data_real_o  <= data_real_out;
      data_imag_o  <= data_imag_out;
      data_exp_o   <= data_exp_out;
    end
  end
  
  //added for test
  //reg [10:0]  sym_cnt;
  //always @(posedge clk_sys or negedge rst_sys_n)
  //  if(!rst_sys_n)
  //    sym_cnt <= 0;
  //  else if(block_sync_i == 1'b1)
  //    sym_cnt <= 0;
  //  else if(data_val_i == 1'b1)
  //    sym_cnt <= sym_cnt + 1;
  //    
      
endmodule

