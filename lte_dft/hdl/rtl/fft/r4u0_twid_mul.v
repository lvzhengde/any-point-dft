/*++
Abstract:
  pipeline fft radix-4 unit 0, multiply with twiddle factors
--*/

`include "macros.v"
`include "fixed_point.v"

module r4u0_twid_mul(
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
	k2_i,
  block_sync_o, 
  next_sync_o, 
  data_val_o, 
  data_real_o,
  data_imag_o, 
  data_exp_o
  //ldn_rg_o
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
	input k2_i;
	output reg block_sync_o;
	output reg next_sync_o;
	output reg data_val_o;
	output reg signed [`MAN_WIDTH-1:0] data_real_o;
	output reg signed [`MAN_WIDTH-1:0] data_imag_o;
	output reg signed [`EXP_WIDTH-1:0] data_exp_o;
	//output reg [3:0] ldn_rg_o;

	reg [1:0] n3_sig;            
	reg  [2:0] n_div_4;   //n_div_4 = n_div_2/2, BF_II connect to BF_I
	
	always @(*) begin
	  case(ldn_rg_i)
	    4'd11:   n_div_4 = 3'd2;     //2048-point
	    4'd10:   n_div_4 = 3'd1;     //1024-point
	    4'd9:    n_div_4 = 3'd2;     //512-point
	    4'd8:    n_div_4 = 3'd1;     //256-point
	    4'd7:    n_div_4 = 3'd2;     //128-point
	    4'd6:    n_div_4 = 3'd1;     //64-point
	    4'd5:    n_div_4 = 3'd2;     //32-point
	    4'd4:    n_div_4 = 3'd1;     //16-point
	    4'd3:    n_div_4 = 3'd2;     //8-point
	    default: n_div_4 = 3'd2;
	  endcase
	end 
	
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      n3_sig <= 0;
    else if (stage_sync_i == 1'b1)
      n3_sig <= 0;
    else if (data_val_i == 1'b1)
      n3_sig <= n3_sig + 1;
  end
  
  reg signed [`MAN_WIDTH+12:0] mul_real, mul_imag;
  reg signed [`MAN_WIDTH-1:0] temp_real, temp_imag;
  reg signed [`MAN_WIDTH-1:0] x_r1, x_r2;
  reg signed [`MAN_WIDTH-1:0] x_i1, x_i2;
  reg signed [`MAN_WIDTH:0]   data_real_p1, data_imag_p1;   
  reg signed [`MAN_WIDTH:0]   data_real_z1, data_imag_z1;             
  reg signed [`MAN_WIDTH:0]   data_real, data_imag;      
  reg signed [`EXP_WIDTH-1:0] data_exp_z1;   
  reg signed [`EXP_WIDTH-1:0] data_exp;
  reg [1:0] k_seg;
  reg [1:0] n3, n, r;
  reg m2;
  reg signed [`MAN_WIDTH:0] abs_max_man;
  reg signed [`MAN_WIDTH:0] abs_x_r;
  reg signed [`MAN_WIDTH:0] abs_x_i;
  reg signed [`MAN_WIDTH:0] max_x;

  always @(*) begin
    m2 = 1'b0;
    //data_real_i*sqrt(2)/2, data_imag_i*sqrt(2)/2, coefficient 1.11
    //mul_real = (data_real_i<<<10)+(data_real_i<<<8)+(data_real_i<<<7)+(data_real_i<<<5)+(data_real_i<<<3);
    //mul_imag = (data_imag_i<<<10)+(data_imag_i<<<8)+(data_imag_i<<<7)+(data_imag_i<<<5)+(data_imag_i<<<3);
    //`SYMRND(mul_real, mul_real, 11);
    //`SYMRND(mul_imag, mul_imag, 11);
    
    //coefficient 1.12
    mul_real = (data_real_i<<<11)+(data_real_i<<<9)+(data_real_i<<<8)+(data_real_i<<<6)+(data_real_i<<<4);
    mul_imag = (data_imag_i<<<11)+(data_imag_i<<<9)+(data_imag_i<<<8)+(data_imag_i<<<6)+(data_imag_i<<<4);
    `SYMRND(mul_real, mul_real, 12);
    `SYMRND(mul_imag, mul_imag, 12);    
    temp_real = mul_real[`MAN_WIDTH-1:0];
    temp_imag = mul_imag[`MAN_WIDTH-1:0];
    
    //default values
    data_real_p1 = 0;
    data_imag_p1 = 0;
      
	  if (data_val_i == 1'b1) begin
	    //determine the twiddle factor at first
	    if (n3_sig == (n_div_4-1))
        n3 = 0;
      else
        n3 = n3_sig + 1;   
        
	    //n = n3 * (k1 + 2*k2);
	    k_seg = k1_i + (k2_i << 1);
      case (k_seg)
        2'b0:  n = 0;
        2'b1:  n = n3;
        2'b10: n = n3 << 1;
        2'b11: n = n3 + (n3 << 1);
      endcase
      
      //n_max=3, thus m1==false for ever
      r = n;
	    if (r >= n_div_4) begin
	      r = r - n_div_4;
	      m2 = 1'b1;
      end  
	   
	    //cos_table: 1, sqrt(2)/2; sin_table: 0, sqrt(2)/2       
	    if (m2 == 1'b0) begin 
	      //twid_real = cos_table_m[r];
	      //twid_imag = -sin_table_m[r];
	      x_r1 = (r == 2'b00) ? data_real_i : temp_real;  //x_r1 = data_real_i*twid_real
	      x_r2 = (r == 2'b00) ? 0 : temp_imag;            //x_r2 = -data_imag_i*twid_imag
	      x_i1 = (r == 2'b00) ? 0 : (-temp_real);         //x_i1 = data_real_i*twid_imag
	      x_i2 = (r == 2'b00) ? data_imag_i : temp_imag;  //x_i2 = data_imag_i*twid_real
	      
	    end
	    else begin
	      //twid_real = -sin_table_m[r];
	      //twid_imag = -cos_table_m[r];
	      x_r1 = (r == 2'b00) ? 0 : (-temp_real);
	      x_r2 = (r == 2'b00) ? data_imag_i : temp_imag;
	      x_i1 = (r == 2'b00) ? (-data_real_i) : (-temp_real);
	      x_i2 = (r == 2'b00) ? 0 : (-temp_imag); 
	    end   
	    
	    data_real_p1 = x_r1 + x_r2;
	    data_imag_p1 = x_i1 + x_i2;
    end
  end
  
  reg block_sync_z1;
  reg data_val_z1;
  reg stage_sync_z1;
  always @(posedge clk_sys) begin
    data_real_z1  <= data_real_p1;
    data_imag_z1  <= data_imag_p1;
    data_exp_z1   <= data_exp_i;
    block_sync_z1 <= block_sync_i;
    data_val_z1   <= data_val_i;
    stage_sync_z1 <= stage_sync_i;
  end
  
  always @(*) begin
    data_real = data_real_z1;
    data_imag = data_imag_z1;
    data_exp  = data_exp_z1;
    //adjust exponent
    abs_max_man = (1 << (`MAN_WIDTH - 1)) - 1;    
    abs_x_r = (data_real >= 0) ? data_real : -data_real;
    abs_x_i = (data_imag >= 0) ? data_imag : -data_imag;
    max_x = (abs_x_r >= abs_x_i) ? abs_x_r : abs_x_i;
    if (max_x > abs_max_man) begin
      data_exp = data_exp_z1 + 1;
      `SYMRND(data_real, data_real, 1);
      `SYMRND(data_imag, data_imag, 1);
    end	   
  end
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      block_sync_o <= 0;  
      next_sync_o  <= 0;   
      data_val_o   <= 0;    
      data_real_o  <= 0;   
      data_imag_o  <= 0;  
      data_exp_o   <= 0;  
      //ldn_rg_o     <= 4'd0;     
    end
    else begin   
      //default value
      block_sync_o <= 0;  
      next_sync_o  <= 0;   
      data_val_o   <= 0;    
      data_real_o  <= 0;   
      data_imag_o  <= 0;  
      data_exp_o   <= 0; 
           
	    if (stage_sync_z1 == 1'b1)
	      next_sync_o <= 1'b1;
	    if (block_sync_z1 == 1'b1) begin
	      block_sync_o <= 1'b1;  
	      //ldn_rg_o    <= ldn_rg_i;
	    end
	    if (data_val_z1 == 1'b1) begin
	      data_val_o  <= 1'b1;	 
	      data_real_o <= data_real[`MAN_WIDTH-1:0];
	      data_imag_o <= data_imag[`MAN_WIDTH-1:0];
	      data_exp_o  <= data_exp[`EXP_WIDTH-1:0];     
	    end   
    end
  end
endmodule
  




