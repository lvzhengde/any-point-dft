/*++
Abstract:
  pipeline fft radix-4 unit 0, butterfly stage I
--*/

`include "macros.v"
`include "fixed_point.v"

module r4u0_bf2_one(
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
  next_sync_o, 
  data_val_o, 
  data_real_o,
  data_imag_o, 
  data_exp_o, 
  //ldn_rg_o,
  k1_o	
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
	output reg next_sync_o;
	output reg data_val_o;
	output reg signed [`MAN_WIDTH-1:0] data_real_o;
	output reg signed [`MAN_WIDTH-1:0] data_imag_o;
	output reg signed [`EXP_WIDTH-1:0] data_exp_o;
	//output reg [3:0] ldn_rg_o;
  output reg k1_o;

	reg get_blk_sync_sig;            
	reg [2:0] input_pos_sig;
	reg [2:0] output_pos_sig;
  reg data_val_z1;
  reg signed [`MAN_WIDTH-1:0] data_real_z1;
  reg signed [`MAN_WIDTH-1:0] data_imag_z1;
  reg signed [`EXP_WIDTH-1:0] data_exp_z1;
  //register banks
	reg signed [`MAN_WIDTH-1:0] x_r_m[3:0];
	reg signed [`MAN_WIDTH-1:0] x_i_m[3:0];
	reg signed [`EXP_WIDTH-1:0] x_exp_m[3:0]; 
	
	reg  [2:0] n_div_2;
	wire [3:0] data_point_m = (n_div_2 << 1);
	
	always @(*) begin
	  case(ldn_rg_i)
	    4'd11:   n_div_2 = 3'd4;     //2048-point
	    4'd10:   n_div_2 = 3'd2;     //1024-point
	    4'd9:    n_div_2 = 3'd4;     //512-point
	    4'd8:    n_div_2 = 3'd2;     //256-point
	    4'd7:    n_div_2 = 3'd4;     //128-point
	    4'd6:    n_div_2 = 3'd2;     //64-point
	    4'd5:    n_div_2 = 3'd4;     //32-point
	    4'd4:    n_div_2 = 3'd2;     //16-point  
	    4'd3:    n_div_2 = 3'd4;     //8-point
	    default: n_div_2 = 3'd4;
	  endcase
	end 
	
	//handle input processing
	wire [2:0] input_pos_p1;
	reg  [2:0] input_pos_z1;	
	always @(posedge clk_sys or negedge rst_sys_n) begin
	  if (!rst_sys_n) begin
	    input_pos_sig <= 0;
	    input_pos_z1  <= 0;
	  end
	  else begin
	    input_pos_z1 <= input_pos_sig;
	    
	    if (data_val_i == 1'b1)
	      input_pos_sig <= input_pos_p1;
	  end
	end
	
	assign input_pos_p1 = (stage_sync_i) ? 0 : input_pos_sig + 1;
	
  always @(posedge clk_sys or negedge rst_sys_n) begin	
    if (!rst_sys_n)
      get_blk_sync_sig <= 1'b0;
    else if (stage_sync_i == 1'b1 && block_sync_i == 1'b1)
      get_blk_sync_sig <= 1'b1;
    else if (block_sync_o == 1'b1)
      get_blk_sync_sig <= 1'b0;
  end
  
	always @(posedge clk_sys) begin
	  data_val_z1     <=  data_val_i;
	  data_real_z1    <=  data_real_i;
	  data_imag_z1    <=  data_imag_i;
	  data_exp_z1     <=  data_exp_i;
	end
  
  reg signed [`MAN_WIDTH:0] bf2_r_out1, bf2_i_out1;
  reg signed [`MAN_WIDTH:0] bf2_r_out2, bf2_i_out2;
  reg signed [`EXP_WIDTH-1:0] bf2_exp_out1, bf2_exp_out2;
  reg  [2:0] buf_addr0; 
  reg  [2:0] buf_addr0_z1;     
  wire [2:0] buf_addr1 = output_pos_sig - n_div_2;   
         	
	always @(posedge clk_sys) begin 
	  if (data_val_z1 == 1'b1 && input_pos_sig < n_div_2) begin
      x_r_m[input_pos_sig]   <= data_real_z1;
      x_i_m[input_pos_sig]   <= data_imag_z1;
      x_exp_m[input_pos_sig] <= data_exp_z1;
    end
    
    else if(data_val_z1 == 1'b1) begin
      x_r_m[buf_addr0_z1]      <= bf2_r_out2[`MAN_WIDTH-1:0];
      x_i_m[buf_addr0_z1]      <= bf2_i_out2[`MAN_WIDTH-1:0];
      x_exp_m[buf_addr0_z1]    <= bf2_exp_out2[`EXP_WIDTH-1:0];        
    end
  end 

  //handle radix-2 butterfly processing
  reg signed [`EXP_WIDTH-1:0] max_exp_in;   
  reg signed [`EXP_WIDTH-1:0] com_exp_in;      
  reg signed [`EXP_WIDTH-1:0] data_exp_in1;
  reg signed [`MAN_WIDTH-1:0] bf2_r_in1, bf2_i_in1;
  reg signed [`EXP_WIDTH-1:0] data_exp_in2;
  reg signed [`MAN_WIDTH-1:0] bf2_r_in2, bf2_i_in2;
  reg signed [`MAN_WIDTH:0]   abs_max_man;
  reg signed [`MAN_WIDTH:0]   abs_r_out1, abs_i_out1, abs_max_out1;
  reg signed [`MAN_WIDTH:0]   abs_r_out2, abs_i_out2, abs_max_out2;    
  reg signed [5:0] cutbits;    
  
  always @(*) begin
    //get the first input
    buf_addr0 = input_pos_p1 - n_div_2;
    bf2_r_in1 = x_r_m[buf_addr0];
    bf2_i_in1 = x_i_m[buf_addr0];
    data_exp_in1 = x_exp_m[buf_addr0];
    //get the second input
    data_exp_in2 = data_exp_i;
    bf2_r_in2 = data_real_i;
    bf2_i_in2 = data_imag_i;
    
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
    max_exp_in_z1  <= max_exp_in;                  
    bf2_r_in1_z1   <= bf2_r_in1;
    bf2_i_in1_z1   <= bf2_i_in1;     
    bf2_r_in2_z1   <= bf2_r_in2; 
    bf2_i_in2_z1   <= bf2_i_in2;
    
    buf_addr0_z1   <= buf_addr0; 
  end
  
  //butterfly algorithm and output scaling
  always @(*) begin 
    //butterfly operation   
    com_exp_in =  max_exp_in_z1  ;    
        
    bf2_r_out1 = bf2_r_in1_z1 + bf2_r_in2_z1;
    bf2_i_out1 = bf2_i_in1_z1 + bf2_i_in2_z1;
    bf2_r_out2 = bf2_r_in1_z1 - bf2_r_in2_z1;
    bf2_i_out2 = bf2_i_in1_z1 - bf2_i_in2_z1;
    
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
      block_sync_o   <= 0;
      next_sync_o    <= 0;
      data_val_o     <= 0;
      data_real_o    <= 0;
      data_imag_o    <= 0;
      data_exp_o     <= 0;
      //ldn_rg_o       <= 4'd0;
      output_pos_sig <= 0;
      k1_o           <= 0;
    end
    else begin
      //default output value
      block_sync_o  <= 0;
      next_sync_o   <= 0;
      data_val_o    <= 0;
      data_real_o   <= 0;
      data_imag_o   <= 0;
      data_exp_o    <= 0;    
      //output the first block of data 
      if (data_val_z1 == 1'b1) begin
        if (input_pos_sig == n_div_2) begin
          k1_o <= 0;
          if (get_blk_sync_sig == 1'b1) begin
            block_sync_o <= 1'b1;          
            //ldn_rg_o <= ldn_rg_i;
          end
          next_sync_o <= 1'b1;
          data_val_o  <= 1'b1;
          data_real_o <= bf2_r_out1[`MAN_WIDTH-1:0];
          data_imag_o <= bf2_i_out1[`MAN_WIDTH-1:0];
          data_exp_o  <= bf2_exp_out1[`EXP_WIDTH-1:0];  
          
          output_pos_sig <= output_pos_sig + 1;        
        end
        else if (input_pos_sig > n_div_2 && output_pos_sig < n_div_2) begin
          data_val_o  <= 1'b1;
          data_real_o <= bf2_r_out1[`MAN_WIDTH-1:0];
          data_imag_o <= bf2_i_out1[`MAN_WIDTH-1:0];
          data_exp_o  <= bf2_exp_out1[`EXP_WIDTH-1:0];  
          
          output_pos_sig <= output_pos_sig + 1;       
        end
      end
      //output the second block of data
      if (output_pos_sig >= n_div_2) begin
        if (output_pos_sig == n_div_2) begin
          k1_o <= 1'b1;
          next_sync_o <= 1'b1;
        end
        data_val_o <= 1'b1;
        data_real_o <= x_r_m[buf_addr1];
        data_imag_o <= x_i_m[buf_addr1];
        data_exp_o <= x_exp_m[buf_addr1];
        
        output_pos_sig <= output_pos_sig + 1; 
      end
      
      if (output_pos_sig == (data_point_m-1))
        output_pos_sig <= 0;  
    end
  end

endmodule
  
