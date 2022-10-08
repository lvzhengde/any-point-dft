/*++
Abstract:
    data type conversion from semi-float to fixed-point
--*/

`include "macros.v"        
`include "fixed_point.v"      

module bfp2fixed(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i, 
  data_imag_i,
  data_exp_i, 
  block_sync_o, 
  data_val_o, 
  data_real_o, 
  data_imag_o
  );
  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input    data_val_i;
  input signed [`MAN_WIDTH-1:0] data_real_i;
  input signed [`MAN_WIDTH-1:0] data_imag_i;
  input signed [`EXP_WIDTH-1:0] data_exp_i;
  output reg block_sync_o;
  output reg data_val_o;
  output reg signed [`FFT_OUT_WIDTH-1:0] data_real_o;
  output reg signed [`FFT_OUT_WIDTH-1:0] data_imag_o;
  
  reg signed [`FFT_OUT_WIDTH-1:0] data_real_out;
  reg signed [`FFT_OUT_WIDTH-1:0] data_imag_out;  

  always @(*) begin : ActComb
    integer data_real;
    integer data_imag;    
    integer shift_count, cutbits;

    shift_count = `FFT_OUT_PTPOS + data_exp_i - (`MAN_WIDTH - 1);
    data_real = data_real_i;
    data_imag = data_imag_i;
    if (shift_count >=0) begin   //left shift
      data_real = data_real <<< shift_count;
      data_imag = data_imag <<< shift_count;
    
      //symmetrical saturation 
      `SYMSAT(data_real, `FFT_OUT_WIDTH);  
      `SYMSAT(data_imag, `FFT_OUT_WIDTH);          
    end
    else begin   //right shift with round
      cutbits = -shift_count;
      `SYMRND(data_real, data_real, cutbits);    
      `SYMRND(data_imag, data_imag, cutbits);           	  
    end
    data_real_out = data_real;
    data_imag_out = data_imag;
  end 
  
  always @(posedge clk_sys or negedge rst_sys_n) begin : ActReg
    if (!rst_sys_n) begin
      block_sync_o <= 0;
      data_val_o <= 0;
      data_real_o <= 0;
      data_imag_o <= 0;
    end
    else  begin
      block_sync_o <= block_sync_i;
      data_val_o <= data_val_i;
      data_real_o <= data_real_out;
      data_imag_o <= data_imag_out;
    end
  end
endmodule
  
