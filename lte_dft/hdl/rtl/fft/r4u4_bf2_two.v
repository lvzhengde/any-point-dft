/*++
Abstract:
  pipeline fft radix-4 unit 4, butterfly stage II
--*/

`include "macros.v"
`include "fixed_point.v"

module r4u4_bf2_two(
  clk_sys, 
  rst_sys_n,
  block_sync_i, 
  stage_sync_i, 
  data_val_i, 
  data_real_i,
	data_imag_i, 
	data_exp_i, 
	ldn_rg_i, 
	k1_i,
  block_sync_o, 
  next_sync_o, 
  data_val_o, 
  data_real_o,
  data_imag_o, 
  data_exp_o,
  //ldn_rg_o, 
  k1_o, 
  k2_o
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
	input k1_i;
	output reg block_sync_o;
	output reg next_sync_o;
	output reg data_val_o;
	output reg signed [`MAN_WIDTH-1:0] data_real_o;
	output reg signed [`MAN_WIDTH-1:0] data_imag_o;
	output reg signed [`EXP_WIDTH-1:0] data_exp_o;
	//output reg [3:0] ldn_rg_o;
  output reg k1_o;
  output reg k2_o;

	reg get_blk_sync_sig;            
	reg [9:0] input_pos_sig;
	reg [9:0] output_pos_sig;	
  reg k1_sig;
  reg data_val_z1;
  reg signed [`MAN_WIDTH-1:0] data_real_z1;
  reg signed [`MAN_WIDTH-1:0] data_imag_z1;
  reg signed [`EXP_WIDTH-1:0] data_exp_z1;      
	reg  [9:0] n_div_4;   //n_div_4 = n_div_2/2, BF_II connect to BF_I
	
  //Instantiate RAM
	reg [8:0]  rd_addr;
	reg [8:0]  wr_addr;
	reg        wr_en;
	wire [`MAN_WIDTH+`MAN_WIDTH+`EXP_WIDTH-1:0] rd_data;
  reg  [`MAN_WIDTH+`MAN_WIDTH+`EXP_WIDTH-1:0] wr_data;
	r4u4_two_ram  r4u4_two_ram(
	  .clk_sys        (clk_sys),
	  .rd_addr        (rd_addr),
	  .rd_data        (rd_data),
	  .wr_en          (wr_en),     //active low
	  .wr_addr        (wr_addr),
	  .wr_data        (wr_data)    //registered output
	);
	
	always @(*) begin
	  case(ldn_rg_i)
	    4'd11: n_div_4 = 10'd512;      //2048-point
	    4'd10: n_div_4 = 10'd256;      //1024-point
	    default: n_div_4 = 10'd512;
	  endcase
	end 
	
	//handle input processing
	wire [9:0] input_pos_p1;	
	reg  [9:0] input_pos_z1;	
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
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      k1_sig <= 1'b0;
    else if (input_pos_p1 == n_div_4)
      k1_sig <= k1_i;
  end
	
	always @(posedge clk_sys) begin
	  data_val_z1     <=   data_val_i;
	  data_real_z1    <=   data_real_i;
	  data_imag_z1    <=   data_imag_i;
	  data_exp_z1     <=   data_exp_i;
	end

  reg signed [`MAN_WIDTH:0] bf2_r_out1, bf2_i_out1;
  reg signed [`MAN_WIDTH:0] bf2_r_out2, bf2_i_out2;
  reg signed [`EXP_WIDTH-1:0] bf2_exp_out1, bf2_exp_out2;
  reg  [8:0] buf_addr0;      
  reg  [8:0] buf_addr0_z1;                
  wire [8:0] buf_addr1 = output_pos_sig - n_div_4;
    
  //write to RAM            	
	always @(posedge clk_sys or negedge rst_sys_n) begin
	  if (!rst_sys_n) begin
	    wr_en <= 1'b1;
	    wr_addr <= 0;
	    wr_data <= 0;
	  end
	  else begin
	    //default value 
	    wr_en <= 1'b1;   
	    wr_addr <= 0;
	    wr_data <= 0;
	    if (data_val_z1 == 1'b1 && input_pos_sig < n_div_4) begin
	        wr_en   <= 1'b0;
	        wr_addr <= input_pos_sig;
	        wr_data <= {data_real_z1, data_imag_z1, data_exp_z1};
	    end 
      else if(data_val_z1 == 1'b1) begin   
	      wr_en   <= 1'b0;
	      wr_addr <= buf_addr0_z1;
	      wr_data <= {bf2_r_out2[`MAN_WIDTH-1:0], bf2_i_out2[`MAN_WIDTH-1:0], bf2_exp_out2[`EXP_WIDTH-1:0]};
      end
    end
  end
  
  reg signed [`MAN_WIDTH-1:0] ram_real_z1;
  reg signed [`MAN_WIDTH-1:0] ram_imag_z1;
  reg signed [`EXP_WIDTH-1:0] ram_exp_z1; 
  //read from RAM, deal with read address
  always @(posedge clk_sys) begin
    ram_real_z1 <= rd_data[`MAN_WIDTH+`MAN_WIDTH+`EXP_WIDTH-1:`MAN_WIDTH+`EXP_WIDTH];  
    ram_imag_z1 <= rd_data[`MAN_WIDTH+`EXP_WIDTH-1:`EXP_WIDTH];                        
    ram_exp_z1  <= rd_data[`EXP_WIDTH-1:0];                                             
  end
  
  reg [8:0]  rd_addr_z1;
  always @(posedge clk_sys)
    if(data_val_i == 1'b1) rd_addr_z1 <= rd_addr;
       
  always @(*) begin
    rd_addr = 0;
    //read in advance
    if (input_pos_sig >= (n_div_4-2) && input_pos_sig < ((n_div_4<<1)-2)) begin
      if (input_pos_sig == (n_div_4-2))
        rd_addr = 0;
      else
        rd_addr = (data_val_i == 1'b1) ? buf_addr0+1 : rd_addr_z1;
    end
    else if(input_pos_sig == ((n_div_4<<1)-2) && data_val_i == 1'b0) begin
      rd_addr = rd_addr_z1;
    end
    else begin
      if (input_pos_sig == ((n_div_4<<1)-2) && data_val_i == 1'b1)
        rd_addr = 0;
      else
        rd_addr = buf_addr1+2;
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
  
  always @(*) begin
    //get the first input
    buf_addr0 = input_pos_p1 - n_div_4;
    bf2_r_in1 = rd_data[`MAN_WIDTH+`MAN_WIDTH+`EXP_WIDTH-1:`MAN_WIDTH+`EXP_WIDTH]; 
    bf2_i_in1 = rd_data[`MAN_WIDTH+`EXP_WIDTH-1:`EXP_WIDTH];
    data_exp_in1 = rd_data[`EXP_WIDTH-1:0];      
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
    com_exp_in =  max_exp_in_z1  ;      
       
    //butterfly operation      
    if (k1_sig == 1'b0) begin
      //butterfly algorithm type I
      bf2_r_out1 = bf2_r_in1_z1 + bf2_r_in2_z1;
      bf2_i_out1 = bf2_i_in1_z1 + bf2_i_in2_z1;
      bf2_r_out2 = bf2_r_in1_z1 - bf2_r_in2_z1;
      bf2_i_out2 = bf2_i_in1_z1 - bf2_i_in2_z1;
    end
    else begin
      //butterfly algorithm type II
      bf2_r_out1 = bf2_r_in1_z1 + bf2_i_in2_z1;
      bf2_i_out1 = bf2_i_in1_z1 - bf2_r_in2_z1;
      bf2_r_out2 = bf2_r_in1_z1 - bf2_i_in2_z1;
      bf2_i_out2 = bf2_i_in1_z1 + bf2_r_in2_z1; 
    end      
    
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
      k2_o           <= 0;
    end
    else begin
      //default output value
      block_sync_o  <= 0;
      next_sync_o   <= 0;
      data_val_o    <= 0;
      data_real_o   <= 0;
      data_imag_o   <= 0;
      data_exp_o    <= 0;    
      //output the first half block of data 
      if (data_val_z1 == 1'b1) begin
        if (input_pos_sig == n_div_4) begin
          k1_o <= k1_sig;
          k2_o <= 0;
          if (get_blk_sync_sig == 1'b1) begin
            block_sync_o <= 1'b1;          
            //ldn_rg_o     <= ldn_rg_i;
          end
          next_sync_o    <= 1'b1;
          data_val_o     <= 1'b1;
          data_real_o    <= bf2_r_out1[`MAN_WIDTH-1:0];
          data_imag_o    <= bf2_i_out1[`MAN_WIDTH-1:0];
          data_exp_o     <= bf2_exp_out1[`EXP_WIDTH-1:0];  
          
          output_pos_sig <= output_pos_sig + 1;        
        end
        else if (input_pos_sig > n_div_4 && output_pos_sig < n_div_4) begin
          data_val_o  <= 1'b1;;
          data_real_o <= bf2_r_out1[`MAN_WIDTH-1:0];
          data_imag_o <= bf2_i_out1[`MAN_WIDTH-1:0];
          data_exp_o  <= bf2_exp_out1[`EXP_WIDTH-1:0];  
          
          output_pos_sig <= output_pos_sig + 1;      
        end
      end
      
      //output the second half block of data
      if (output_pos_sig >= n_div_4) begin
        if (output_pos_sig == n_div_4) begin
          k2_o        <= 1'b1;
          next_sync_o <= 1'b1;
        end
        data_val_o  <= 1'b1;
        data_real_o <= ram_real_z1 ;
        data_imag_o <= ram_imag_z1 ;
        data_exp_o  <= ram_exp_z1  ;
        
        output_pos_sig <= output_pos_sig + 1;  
      end
      
      if (output_pos_sig == ((n_div_4<<1)-1))
        output_pos_sig <= 0;      
    end
  end

endmodule
  
