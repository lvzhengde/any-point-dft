/*++
Abstract:
  pipeline fft radix-4 unit 2, top level
--*/

`include "macros.v"
`include "fixed_point.v"

module radix4_unit2(
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
	output block_sync_o;
	output next_sync_o;
	output data_val_o;
	output signed [`MAN_WIDTH-1:0] data_real_o;
	output signed [`MAN_WIDTH-1:0] data_imag_o;
	output signed [`EXP_WIDTH-1:0] data_exp_o;
	//output [3:0] ldn_rg_o;
	
	//inter-connection signals
	wire block_sync1;
	wire next_sync1;
	wire data_val1;
	wire signed [`MAN_WIDTH-1:0] data_real1;
	wire signed [`MAN_WIDTH-1:0] data_imag1;
	wire signed [`EXP_WIDTH-1:0] data_exp1;
	//wire [3:0]  ldn_rg_1;
	wire k1_1;
	
	wire block_sync2;                            
	wire next_sync2;                             
	wire data_val2;                              
	wire signed [`MAN_WIDTH-1:0] data_real2;     
	wire signed [`MAN_WIDTH-1:0] data_imag2;     
	wire signed [`EXP_WIDTH-1:0] data_exp2;
	//wire [3:0]  ldn_rg_2;      
	wire k1_2;
	wire k2_2;                                   
	
  r4u2_bf2_one r4u2_bf2_one(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n),
    .block_sync_i   (block_sync_i), 
    .stage_sync_i   (stage_sync_i), 
    .data_val_i     (data_val_i), 
    .data_real_i    (data_real_i),
  	.data_imag_i    (data_imag_i), 
  	.data_exp_i     (data_exp_i), 
  	.ldn_rg_i       (ldn_rg_i),
  	
    .block_sync_o   (block_sync1), 
    .next_sync_o    (next_sync1), 
    .data_val_o     (data_val1), 
    .data_real_o    (data_real1),
    .data_imag_o    (data_imag1), 
    .data_exp_o     (data_exp1), 
    //.ldn_rg_o       (ldn_rg_1),
    .k1_o           (k1_1)	
  );
  
  r4u2_bf2_two r4u2_bf2_two(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n),
    .block_sync_i   (block_sync1), 
    .stage_sync_i   (next_sync1), 
    .data_val_i     (data_val1), 
    .data_real_i    (data_real1),
  	.data_imag_i    (data_imag1), 
  	.data_exp_i     (data_exp1), 
  	.ldn_rg_i       (ldn_rg_i), 
  	.k1_i           (k1_1),
  	
    .block_sync_o   (block_sync2), 
    .next_sync_o    (next_sync2), 
    .data_val_o     (data_val2), 
    .data_real_o    (data_real2),
    .data_imag_o    (data_imag2), 
    .data_exp_o     (data_exp2), 
    //.ldn_rg_o       (ldn_rg_2),
    .k1_o           (k1_2), 
    .k2_o           (k2_2)
  );
  
  r4u2_twid_mul r4u2_twid_mul(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n),
    .block_sync_i   (block_sync2), 
    .stage_sync_i   (next_sync2), 
    .data_val_i     (data_val2), 
    .data_real_i    (data_real2),
  	.data_imag_i    (data_imag2), 
  	.data_exp_i     (data_exp2), 
  	.ldn_rg_i       (ldn_rg_i), 
  	.k1_i           (k1_2), 
  	.k2_i           (k2_2),
  	
    .block_sync_o   (block_sync_o), 
    .next_sync_o    (next_sync_o), 
    .data_val_o     (data_val_o), 
    .data_real_o    (data_real_o),
    .data_imag_o    (data_imag_o), 
    .data_exp_o     (data_exp_o)
    //.ldn_rg_o       (ldn_rg_o)
  );
  
  //integer  test_file;
  //always @(posedge clk_sys) begin
  //  if(data_val1 == 1'b1)
  //    $fdisplay(test_file,"%d      %d      %d", data_real1, data_imag1, data_exp1);    
  //end
    
endmodule
  
