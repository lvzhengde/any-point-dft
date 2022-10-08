/*++
Abstract:
  pipeline fft radix-4 unit 3, multiply with twiddle factors
--*/

`include "macros.v"
`include "fixed_point.v"

module r4u3_twid_mul(
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

	reg [7:0] n3_sig;            
	reg [7:0] n_div_4;   //n_div_4 = n_div_2/2, BF_II connect to BF_I
	
	reg block_sync_z1;
  reg stage_sync_z1;
  reg data_val_z1;	  
	
	reg addr_x2_en;
	
	//Instantiate twiddle factor ROM
	reg  [6:0]  rom_addr;
	wire [2*`COEF_WIDTH-1:0] rom_data;  
	r4u3_rom r4u3_rom(
	  .rom_addr      (rom_addr),
	  .rom_data      (rom_data)
	);
	
	always @(*) begin
	  case(ldn_rg_i)
	    4'd11: n_div_4 = 8'd128;     //2048-point
	    4'd10: n_div_4 = 8'd64;      //1024-point
	    4'd9:  n_div_4 = 8'd128;     //512-point
	    4'd8:  n_div_4 = 8'd64;      //256-point
	    default: n_div_4 = 8'd128;
	  endcase
	end 
	
	always @(posedge clk_sys or negedge rst_sys_n)
	  if (!rst_sys_n)
	    addr_x2_en <= 0;
	  else if (n_div_4 == 8'd64)
	    addr_x2_en <= 1;
	  else
	    addr_x2_en <= 0;
	
	always @(posedge clk_sys) begin
    block_sync_z1 <= block_sync_i;
    stage_sync_z1 <= stage_sync_i;
    data_val_z1 <= data_val_i;	  
	end
		
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      n3_sig <= (n_div_4-1);
    else if (stage_sync_i == 1'b1)
      n3_sig <= 0;
    else if (data_val_i == 1'b1)
      n3_sig <= n3_sig + 1;
  end
  
  wire signed [`COEF_WIDTH-1:0] cos_val = rom_data[2*`COEF_WIDTH-1:`COEF_WIDTH];
  wire signed [`COEF_WIDTH-1:0] sin_val = rom_data[`COEF_WIDTH-1:0];
   
  reg signed [`MAN_WIDTH+`COEF_WIDTH-1:0] temp1, temp2, temp3;
  reg signed [`MAN_WIDTH+`COEF_WIDTH-1:0] temp1_z1, temp2_z1, temp3_z1;  
  reg signed [`MAN_WIDTH+`COEF_WIDTH-1:0] tmpdat1, tmpdat2, tmpdat3;  
  reg signed [`COEF_WIDTH-1:0] twid_real, twid_imag;
  reg signed [`MAN_WIDTH:0]   data_real, data_imag;
  reg signed [`EXP_WIDTH-1:0] data_exp;
  reg [1:0] k_seg;
  reg [8:0] n3, n, r;
  reg m1;
  reg m2;
  reg signed [`MAN_WIDTH:0] abs_max_man;
  reg signed [`MAN_WIDTH:0] abs_x_r;
  reg signed [`MAN_WIDTH:0] abs_x_i;
  reg signed [`MAN_WIDTH:0] max_x;  
  //In first cycle, read twiddle factors from ROM, do complex multiplication
  always @(*) begin
    m1 = 0;
    m2 = 0;
    
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
    
    //generate rom address 
    r = n;
	  if (r >= (n_div_4<<1)) begin
	    r = r - (n_div_4<<1);
	    m1 = 1'b1;
	  end
	  if (r >= n_div_4) begin
	    r = r - n_div_4;
	    m2 = 1'b1;
	  end  
	  rom_addr = (addr_x2_en == 1'b0) ? r[6:0] : {r[5:0],1'b0};
	  
	  //get twiddle factor in the same cycle
	  if (m1 == 0 && m2 == 0) begin
	    twid_real = cos_val;
	    twid_imag = -sin_val;
	  end
	  else if (m1 == 1 && m2 == 0) begin
	    twid_real = -cos_val;
	    twid_imag = sin_val;
	  end
	  else if (m1 == 0 && m2 == 1) begin
	    twid_real = -sin_val;
	    twid_imag = -cos_val;
	  end
	  else begin
	    twid_real = sin_val;
	    twid_imag = cos_val;
	  end
	  
	  //multiply input data with twiddle factors
	  //result width: (man_width_m+1-1)+(coef_width_m-1)+1
	  //=man_width_m+coef_width_m
	  temp1 = (data_real_i + data_imag_i) * twid_real; 
	  temp2 = data_imag_i * (twid_imag + twid_real);
	  temp3 = data_real_i * (twid_imag - twid_real);	     
  end
  
  reg signed [`EXP_WIDTH-1:0] data_exp_z1;
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      temp1_z1 <= 0;
      temp2_z1 <= 0;
      temp3_z1 <= 0;
      data_exp_z1 <= 0;
    end
    else begin
      temp1_z1 <= temp1;
      temp2_z1 <= temp2;
      temp3_z1 <= temp3;
      data_exp_z1 <= data_exp_i;
    end
  end
  
  //In second cycle, do additions and output scaling
  always @(*) begin
    data_exp = data_exp_z1;               
    
    tmpdat1 = temp1_z1;
    tmpdat2 = temp2_z1;
    tmpdat3 = temp3_z1;
    `SYMRND(tmpdat1, tmpdat1, `COEF_WIDTH-1);
    `SYMRND(tmpdat2, tmpdat2, `COEF_WIDTH-1);
    `SYMRND(tmpdat3, tmpdat3, `COEF_WIDTH-1);
    
    //man_width_m+1 bits adder
	  data_real = tmpdat1 - tmpdat2;
	  data_imag = tmpdat1 + tmpdat3;

    //Ouput scaling
    abs_max_man = (1 << (`MAN_WIDTH - 1)) - 1;    
    abs_x_r = (data_real >= 0) ? data_real : -data_real;
    abs_x_i = (data_imag >= 0) ? data_imag : -data_imag;
    max_x = (abs_x_r >= abs_x_i) ? abs_x_r : abs_x_i;
    if (max_x > abs_max_man) begin
      data_exp = data_exp + 1;
      `SYMRND(data_real, data_real, 1);
      `SYMRND(data_imag, data_imag, 1);
    end 
  end

  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      block_sync_o <= 0;  
      next_sync_o <= 0;   
      data_val_o <= 0;    
      data_real_o <= 0;   
      data_imag_o <= 0;  
      data_exp_o <= 0;  
      //ldn_rg_o <= 4'd0;     
    end
    else begin   
      //default value
      block_sync_o <= 0;  
      next_sync_o <= 0;   
      data_val_o <= 0;    
      data_real_o <= 0;   
      data_imag_o <= 0;  
      data_exp_o <= 0; 
           
	    if (stage_sync_z1 == 1'b1)
	      next_sync_o <= 1'b1;
	    if (block_sync_z1 == 1'b1) begin
	      block_sync_o <= 1'b1;  
	      //ldn_rg_o <= ldn_rg_i;
	    end
	    if (data_val_z1 == 1'b1) begin
	      data_val_o <= 1'b1;	 
	      data_real_o <= data_real[`MAN_WIDTH-1:0];
	      data_imag_o <= data_imag[`MAN_WIDTH-1:0];
	      data_exp_o <= data_exp[`EXP_WIDTH-1:0];     
	    end   
    end
  end
endmodule
  
