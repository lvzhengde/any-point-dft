/*++
Abstract:
  pipeline fft radix-2 unit
--*/

`include "macros.v"
`include "fixed_point.v"

module radix2_unit(
  clk_sys, 
  rst_sys_n,
  block_sync_i, 
  stage_sync_i, 
  data_val_i, 
  data_real_i,
	data_imag_i, 
	data_exp_i, 
	ldn_rg_i,
  block_sync_o, 
  data_val_o, 
  data_real_o,
  data_imag_o, 
  data_exp_o	
);
 	input clk_sys;
	input rst_sys_n;	
  input block_sync_i;
  input stage_sync_i;
  input data_val_i;
	input signed [`MAN_WIDTH-1:0] data_real_i;
	input signed [`MAN_WIDTH-1:0] data_imag_i;
	input signed [`EXP_WIDTH-1:0] data_exp_i;	
	input [3:0] ldn_rg_i;
	output reg block_sync_o;
	output reg data_val_o;
	output reg signed [`MAN_WIDTH-1:0] data_real_o;
	output reg signed [`MAN_WIDTH-1:0] data_imag_o;
	output reg signed [`EXP_WIDTH-1:0] data_exp_o;

  reg data_val_z1;
  reg stage_sync_z1;
	reg get_blk_sync_sig;   
	reg freeze_work;    
	reg send_second_data;     	
	reg signed [`MAN_WIDTH-1:0] x_r_m;
	reg signed [`MAN_WIDTH-1:0] x_i_m;
	reg signed [`EXP_WIDTH-1:0] x_exp_m; 
	reg signed [`MAN_WIDTH-1:0] x_r_m1;
	reg signed [`MAN_WIDTH-1:0] x_i_m1;
	reg signed [`EXP_WIDTH-1:0] x_exp_m1; 	
	
	always @(*) begin
    if (ldn_rg_i == 4'd10 || ldn_rg_i == 4'd8 || ldn_rg_i == 4'd6 || ldn_rg_i ==4'd4)
	    freeze_work <= 1;
	  else
	    freeze_work <=0;
	end
	
	//handle input processing	
  always @(posedge clk_sys or negedge rst_sys_n) begin	
    if (!rst_sys_n)
      get_blk_sync_sig <= 1'b0;
    else if (stage_sync_i == 1'b1 && block_sync_i == 1'b1)
      get_blk_sync_sig <= 1'b1;
    else if(block_sync_o == 1'b1)
      get_blk_sync_sig <= 1'b0;
  end
	
  reg signed [`MAN_WIDTH:0] bf2_r_out1, bf2_i_out1;
  reg signed [`MAN_WIDTH:0] bf2_r_out2, bf2_i_out2;
  reg signed [`EXP_WIDTH-1:0] bf2_exp_out1, bf2_exp_out2;              	
	always @(posedge clk_sys or negedge rst_sys_n) begin
	  if (!rst_sys_n) begin
      x_r_m    <= 0;
      x_i_m    <= 0;
      x_exp_m  <= 0; 
      x_r_m1   <= 0;      
      x_i_m1   <= 0;      
      x_exp_m1 <= 0;      
      
	  end
	  else if (freeze_work == 1'b0) begin
	    if (data_val_i == 1'b1 && stage_sync_i == 1'b1 ) begin
       x_r_m   <= data_real_i;
       x_i_m   <= data_imag_i;
       x_exp_m <= data_exp_i;
      end
      
      if(data_val_z1 == 1'b1) begin
        x_r_m1   <= bf2_r_out2[`MAN_WIDTH-1:0];
        x_i_m1   <= bf2_i_out2[`MAN_WIDTH-1:0];
        x_exp_m1 <= bf2_exp_out2[`EXP_WIDTH-1:0];        
      end 
    end
  end

  //handle radix-2 butterfly processing
  reg signed [`EXP_WIDTH-1:0] max_exp_in;  
  reg signed [`EXP_WIDTH-1:0] com_exp_in;    
  reg signed [`EXP_WIDTH-1:0] data_exp_in1;
  reg signed [`MAN_WIDTH-1:0] bf2_r_in1, bf2_i_in1;
  reg signed [`EXP_WIDTH-1:0] data_exp_in2;
  reg signed [`MAN_WIDTH-1:0] bf2_r_in2, bf2_i_in2;
  reg signed [`MAN_WIDTH:0] abs_max_man;
  reg signed [`MAN_WIDTH:0] abs_r_out1, abs_i_out1, abs_max_out1;
  reg signed [`MAN_WIDTH:0] abs_r_out2, abs_i_out2, abs_max_out2;    
  reg signed [5:0] cutbits;  
      
  always @(*) begin      //input scaling
    //get the first input
    bf2_r_in1    = x_r_m;
    bf2_i_in1    = x_i_m;
    data_exp_in1 = x_exp_m;
    //get the second input
    data_exp_in2 = data_exp_i;
    bf2_r_in2    = data_real_i;
    bf2_i_in2    = data_imag_i;
    
    //input scaling
    if (data_exp_in1 >= data_exp_in2) begin
      max_exp_in = data_exp_in1;
      cutbits = data_exp_in1 - data_exp_in2;
      if (cutbits < `MAN_WIDTH) begin
        `SYMRND(bf2_r_in2, bf2_r_in2, cutbits);    
        `SYMRND(bf2_i_in2, bf2_i_in2, cutbits);  
      end 
      else begin
        bf2_r_in2 = 0;
        bf2_i_in2 = 0;
      end
    end
    else begin
      max_exp_in = data_exp_in2;
      cutbits = data_exp_in2 - data_exp_in1;
      if (cutbits < `MAN_WIDTH) begin
        `SYMRND(bf2_r_in1, bf2_r_in1, cutbits);
        `SYMRND(bf2_i_in1, bf2_i_in1, cutbits); 
      end
      else begin
        bf2_r_in1 = 0;
        bf2_i_in1 = 0;
      end 
    end    
  end

  reg signed [`EXP_WIDTH-1:0] max_exp_in_z1;                   
  reg signed [`MAN_WIDTH-1:0] bf2_r_in1_z1, bf2_i_in1_z1;                      
  reg signed [`MAN_WIDTH-1:0] bf2_r_in2_z1, bf2_i_in2_z1;   
  
  always @(posedge clk_sys) begin
    max_exp_in_z1   <= max_exp_in;
    bf2_r_in1_z1    <= bf2_r_in1;
    bf2_i_in1_z1    <= bf2_i_in1;
    bf2_r_in2_z1    <= bf2_r_in2;
    bf2_i_in2_z1    <= bf2_i_in2;   
    
    data_val_z1     <= data_val_i; 
    stage_sync_z1   <= stage_sync_i;
  end      

  //butterfly algorithm and output scaling
  always @(*) begin    
    //butterfly operation
    bf2_r_out1 = bf2_r_in1_z1 + bf2_r_in2_z1;
    bf2_i_out1 = bf2_i_in1_z1 + bf2_i_in2_z1;
    bf2_r_out2 = bf2_r_in1_z1 - bf2_r_in2_z1;
    bf2_i_out2 = bf2_i_in1_z1 - bf2_i_in2_z1;
    
    com_exp_in = max_exp_in_z1;
    
    //output scaling        
    abs_max_man = (1 << (`MAN_WIDTH - 1)) - 1;    
    //for the first output
    abs_r_out1 = (bf2_r_out1 >= 0) ? bf2_r_out1 : -bf2_r_out1;
    abs_i_out1 = (bf2_i_out1 >= 0) ? bf2_i_out1 : -bf2_i_out1;      
    abs_max_out1 = (abs_r_out1 >= abs_i_out1) ? abs_r_out1 : abs_i_out1;
    if (abs_max_out1 > abs_max_man) begin //overflow occurred
      bf2_exp_out1 = com_exp_in + 1;
      `SYMRND(bf2_r_out1, bf2_r_out1, 1);
      `SYMRND(bf2_i_out1, bf2_i_out1, 1);
    end
    else begin
      bf2_exp_out1 = com_exp_in;
      bf2_r_out1 = bf2_r_out1;
      bf2_i_out1 = bf2_i_out1;     
    end 
    //for the second output
    abs_r_out2 = (bf2_r_out2 >= 0) ? bf2_r_out2 : -bf2_r_out2;
    abs_i_out2 = (bf2_i_out2 >= 0) ? bf2_i_out2 : -bf2_i_out2;      
    abs_max_out2 = (abs_r_out2 >= abs_i_out2) ? abs_r_out2 : abs_i_out2;
    if (abs_max_out2 > abs_max_man) begin //overflow occurred
      bf2_exp_out2 = com_exp_in + 1;
       `SYMRND(bf2_r_out2, bf2_r_out2, 1);
       `SYMRND(bf2_i_out2, bf2_i_out2, 1);
    end
    else begin
      bf2_exp_out2 = com_exp_in;
      bf2_r_out2 = bf2_r_out2;
      bf2_i_out2 = bf2_i_out2;     
    end                                         
  end

  //handle output to next stage processing
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      block_sync_o  <= 0;
      data_val_o    <= 0;
      data_real_o   <= 0;
      data_imag_o   <= 0;
      data_exp_o    <= 0;
    end
    else begin
      //default output value
      block_sync_o  <= 0;
      data_val_o    <= 0;
      data_real_o   <= 0;
      data_imag_o   <= 0;
      data_exp_o    <= 0;    
      //output the first data 
      if (data_val_z1 == 1'b1 && stage_sync_z1 == 1'b0 && freeze_work == 1'b0) begin
          if (get_blk_sync_sig == 1'b1)
            block_sync_o <= 1'b1;          
          data_val_o  <= 1'b1;
          data_real_o <= bf2_r_out1[`MAN_WIDTH-1:0];
          data_imag_o <= bf2_i_out1[`MAN_WIDTH-1:0];
          data_exp_o  <= bf2_exp_out1[`EXP_WIDTH-1:0];  
      end
      //output the second data
      else if (freeze_work == 1'b0 && send_second_data == 1'b1) begin
        data_val_o  <= 1'b1;
        data_real_o <= x_r_m1;
        data_imag_o <= x_i_m1;
        data_exp_o  <= x_exp_m1;  
      end
    end
  end
  
  always @(posedge clk_sys or negedge rst_sys_n)
    if (!rst_sys_n)
      send_second_data <= 0;
    else if (data_val_z1 == 1'b1 && stage_sync_z1 == 1'b0 && freeze_work == 1'b0)
      send_second_data <= 1;
    else if (freeze_work == 1'b0 && send_second_data == 1'b1)
      send_second_data <= 0;


  //dump for test
  //integer  test_file;
  //always @(posedge clk_sys) begin
  //  if(data_val_o == 1'b1)
  //    $fdisplay(test_file,"%d      %d      %d", data_real_o, data_imag_o, data_exp_o);    
  //end 
         
endmodule
  


