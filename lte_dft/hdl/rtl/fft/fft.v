/*++
Abstract:
    Radix2^2 FFT top level
--*/

`include "macros.v"
`include "fixed_point.v"

module fft(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i,
  data_imag_i,
  ldn_rg_i,
  block_sync_o, 
  data_val_o, 
  data_real_o, 
  data_imag_o
  //ldn_rg_o
  );

  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input    data_val_i;
  input signed [`FFT_IN_WIDTH-1:0] data_real_i;
  input signed [`FFT_IN_WIDTH-1:0] data_imag_i;
  input [3:0]  ldn_rg_i;
  output block_sync_o;
  output data_val_o;
  output signed [`FFT_OUT_WIDTH-1:0] data_real_o;
  output signed [`FFT_OUT_WIDTH-1:0] data_imag_o;
  //output [3:0] ldn_rg_o;

  //glue logics
  //reg [3:0] ldn_rg_z1;
  //always @(posedge clk_sys or negedge rst_sys_n)
  //  if (!rst_sys_n)
  //    ldn_rg_z1 <= 4'd0;
  //  else if (block_sync_i == 1'b1)
  //    ldn_rg_z1 <= ldn_rg_i;

  //Instantiate fixed-point to semi-float module
  wire fixed2bfp_block_sync;
  wire fixed2bfp_data_val;
  wire signed [`MAN_WIDTH-1:0] fixed2bfp_data_real;
  wire signed [`MAN_WIDTH-1:0] fixed2bfp_data_imag;
  wire signed [`EXP_WIDTH-1:0] fixed2bfp_data_exp;
  
  fixed2bfp fixed2bfp(
   .clk_sys         (clk_sys), 
   .rst_sys_n       (rst_sys_n), 
   .block_sync_i    (block_sync_i), 
   .data_val_i      (data_val_i), 
   .data_real_i     (data_real_i),
   .data_imag_i     (data_imag_i),
   .block_sync_o    (fixed2bfp_block_sync), 
   .data_val_o      (fixed2bfp_data_val), 
   .data_real_o     (fixed2bfp_data_real), 
   .data_imag_o     (fixed2bfp_data_imag),
   .data_exp_o      (fixed2bfp_data_exp)
   );
   
  //Instantiate Radix-4 Unit 4 
  reg  r4u4_block_sync_in;
  reg  r4u4_data_val_in;
  reg  signed [`MAN_WIDTH-1:0] r4u4_data_real_in;
  reg  signed [`MAN_WIDTH-1:0] r4u4_data_imag_in;
  reg  signed [`EXP_WIDTH-1:0] r4u4_data_exp_in;   
  wire r4u4_block_sync_out;
  wire r4u4_data_val_out;
  wire signed [`MAN_WIDTH-1:0] r4u4_data_real_out;
  wire signed [`MAN_WIDTH-1:0] r4u4_data_imag_out;
  wire signed [`EXP_WIDTH-1:0] r4u4_data_exp_out;     
  //wire [3:0] r4u4_ldn_rg_out;
  
  always @(*) begin
    if (ldn_rg_i == 4'd11 || ldn_rg_i == 4'd10) begin
      r4u4_block_sync_in = fixed2bfp_block_sync; 
      r4u4_data_val_in   = fixed2bfp_data_val;  
      r4u4_data_real_in  = fixed2bfp_data_real;  
      r4u4_data_imag_in  = fixed2bfp_data_imag;  
      r4u4_data_exp_in   = fixed2bfp_data_exp;
    end
    else begin
      r4u4_block_sync_in = 1'b0; 
      r4u4_data_val_in   = 1'b0;  
      r4u4_data_real_in  = 0;  
      r4u4_data_imag_in  = 0;  
      r4u4_data_exp_in   = 0;    
    end
  end   
      
  radix4_unit4 radix4_unit4(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n),
    .block_sync_i   (r4u4_block_sync_in), 
    .stage_sync_i   (r4u4_block_sync_in), 
    .data_val_i     (r4u4_data_val_in), 
    .data_real_i    (r4u4_data_real_in),
  	.data_imag_i    (r4u4_data_imag_in), 
  	.data_exp_i     (r4u4_data_exp_in), 
  	.ldn_rg_i       (ldn_rg_i), 
    .block_sync_o   (r4u4_block_sync_out), 
    .next_sync_o    (r4u4_next_sync_out), 
    .data_val_o     (r4u4_data_val_out), 
    .data_real_o    (r4u4_data_real_out),
    .data_imag_o    (r4u4_data_imag_out), 
    .data_exp_o     (r4u4_data_exp_out)
    //.ldn_rg_o       (r4u4_ldn_rg_out)
  );   
  
  //Instantiate Radix-4 Unit 3 and Mux3
  reg  mux3_block_sync;
  reg  mux3_stage_sync;
  reg  mux3_data_val;
  reg  signed [`MAN_WIDTH-1:0] mux3_data_real;
  reg  signed [`MAN_WIDTH-1:0] mux3_data_imag;
  reg  signed [`EXP_WIDTH-1:0] mux3_data_exp;   
  //reg  [3:0] mux3_ldn_rg;
  wire r4u3_block_sync;
  wire r4u3_next_sync;
  wire r4u3_data_val;
  wire signed [`MAN_WIDTH-1:0] r4u3_data_real;
  wire signed [`MAN_WIDTH-1:0] r4u3_data_imag;
  wire signed [`EXP_WIDTH-1:0] r4u3_data_exp;     
  //wire [3:0] r4u3_ldn_rg;
  
  always @(*) begin
    if (ldn_rg_i == 4'd9 || ldn_rg_i == 4'd8) begin
      mux3_block_sync = fixed2bfp_block_sync;
      mux3_stage_sync = fixed2bfp_block_sync;
      mux3_data_val   = fixed2bfp_data_val;
      mux3_data_real  = fixed2bfp_data_real;
      mux3_data_imag  = fixed2bfp_data_imag;
      mux3_data_exp   = fixed2bfp_data_exp;   
      //mux3_ldn_rg     = ldn_rg_z1;    
    end
    else begin
      mux3_block_sync = r4u4_block_sync_out;
      mux3_stage_sync = r4u4_next_sync_out;
      mux3_data_val   = r4u4_data_val_out;
      mux3_data_real  = r4u4_data_real_out;
      mux3_data_imag  = r4u4_data_imag_out;
      mux3_data_exp   = r4u4_data_exp_out;   
      //mux3_ldn_rg     = r4u4_ldn_rg_out;        
    end
  end
  
  radix4_unit3 radix4_unit3(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n),
    .block_sync_i   (mux3_block_sync), 
    .stage_sync_i   (mux3_stage_sync), 
    .data_val_i     (mux3_data_val), 
    .data_real_i    (mux3_data_real),
  	.data_imag_i    (mux3_data_imag), 
  	.data_exp_i     (mux3_data_exp), 
  	.ldn_rg_i       (ldn_rg_i), 
    .block_sync_o   (r4u3_block_sync), 
    .next_sync_o    (r4u3_next_sync), 
    .data_val_o     (r4u3_data_val), 
    .data_real_o    (r4u3_data_real),
    .data_imag_o    (r4u3_data_imag), 
    .data_exp_o     (r4u3_data_exp)
    //.ldn_rg_o       (r4u3_ldn_rg)
  );

  //Instantiate Radix-4 Unit 2 and Mux2
  reg  mux2_block_sync;
  reg  mux2_stage_sync;
  reg  mux2_data_val;
  reg  signed [`MAN_WIDTH-1:0] mux2_data_real;
  reg  signed [`MAN_WIDTH-1:0] mux2_data_imag;
  reg  signed [`EXP_WIDTH-1:0] mux2_data_exp;   
  //reg  [3:0] mux2_ldn_rg;
  wire r4u2_block_sync;
  wire r4u2_next_sync;
  wire r4u2_data_val;
  wire signed [`MAN_WIDTH-1:0] r4u2_data_real;
  wire signed [`MAN_WIDTH-1:0] r4u2_data_imag;
  wire signed [`EXP_WIDTH-1:0] r4u2_data_exp;     
  //wire [3:0] r4u2_ldn_rg;
  
  always @(*) begin
    if (ldn_rg_i == 4'd7 || ldn_rg_i == 4'd6) begin
      mux2_block_sync = fixed2bfp_block_sync;
      mux2_stage_sync = fixed2bfp_block_sync;
      mux2_data_val   = fixed2bfp_data_val;
      mux2_data_real  = fixed2bfp_data_real;
      mux2_data_imag  = fixed2bfp_data_imag;
      mux2_data_exp   = fixed2bfp_data_exp;   
      //mux2_ldn_rg     = ldn_rg_z1;    
    end
    else begin
      mux2_block_sync = r4u3_block_sync;
      mux2_stage_sync = r4u3_next_sync;
      mux2_data_val   = r4u3_data_val;
      mux2_data_real  = r4u3_data_real;
      mux2_data_imag  = r4u3_data_imag;
      mux2_data_exp   = r4u3_data_exp;   
      //mux2_ldn_rg     = r4u3_ldn_rg;        
    end
  end
  
  radix4_unit2 radix4_unit2(
    .clk_sys        (clk_sys),         
    .rst_sys_n      (rst_sys_n),      
    .block_sync_i   (mux2_block_sync), 
    .stage_sync_i   (mux2_stage_sync),  
    .data_val_i     (mux2_data_val),   
    .data_real_i    (mux2_data_real), 
  	.data_imag_i    (mux2_data_imag),  
  	.data_exp_i     (mux2_data_exp),   
  	.ldn_rg_i       (ldn_rg_i),     
    .block_sync_o   (r4u2_block_sync), 
    .next_sync_o    (r4u2_next_sync),  
    .data_val_o     (r4u2_data_val),   
    .data_real_o    (r4u2_data_real), 
    .data_imag_o    (r4u2_data_imag),  
    .data_exp_o     (r4u2_data_exp) 
    //.ldn_rg_o       (r4u2_ldn_rg)    
  );  

  //Instantiate Radix-4 Unit 1 and Mux1
  reg  mux1_block_sync;
  reg  mux1_stage_sync;
  reg  mux1_data_val;
  reg  signed [`MAN_WIDTH-1:0] mux1_data_real;
  reg  signed [`MAN_WIDTH-1:0] mux1_data_imag;
  reg  signed [`EXP_WIDTH-1:0] mux1_data_exp;   
  //reg  [3:0] mux1_ldn_rg;
  wire r4u1_block_sync;
  wire r4u1_next_sync;
  wire r4u1_data_val;
  wire signed [`MAN_WIDTH-1:0] r4u1_data_real;
  wire signed [`MAN_WIDTH-1:0] r4u1_data_imag;
  wire signed [`EXP_WIDTH-1:0] r4u1_data_exp;     
  //wire [3:0] r4u1_ldn_rg;
  
  always @(*) begin
    if (ldn_rg_i == 4'd5 || ldn_rg_i == 4'd4) begin
      mux1_block_sync = fixed2bfp_block_sync;
      mux1_stage_sync = fixed2bfp_block_sync;
      mux1_data_val   = fixed2bfp_data_val;
      mux1_data_real  = fixed2bfp_data_real;
      mux1_data_imag  = fixed2bfp_data_imag;
      mux1_data_exp   = fixed2bfp_data_exp;   
      //mux1_ldn_rg     = ldn_rg_z1;    
    end
    else begin
      mux1_block_sync = r4u2_block_sync;
      mux1_stage_sync = r4u2_next_sync;
      mux1_data_val   = r4u2_data_val;
      mux1_data_real  = r4u2_data_real;
      mux1_data_imag  = r4u2_data_imag;
      mux1_data_exp   = r4u2_data_exp;   
      //mux1_ldn_rg     = r4u2_ldn_rg;        
    end
  end
  
  radix4_unit1 radix4_unit1(
    .clk_sys        (clk_sys),         
    .rst_sys_n      (rst_sys_n),      
    .block_sync_i   (mux1_block_sync), 
    .stage_sync_i   (mux1_stage_sync),  
    .data_val_i     (mux1_data_val),   
    .data_real_i    (mux1_data_real), 
  	.data_imag_i    (mux1_data_imag),  
  	.data_exp_i     (mux1_data_exp),   
  	.ldn_rg_i       (ldn_rg_i),     
    .block_sync_o   (r4u1_block_sync), 
    .next_sync_o    (r4u1_next_sync),  
    .data_val_o     (r4u1_data_val),   
    .data_real_o    (r4u1_data_real), 
    .data_imag_o    (r4u1_data_imag),  
    .data_exp_o     (r4u1_data_exp)
    //.ldn_rg_o       (r4u1_ldn_rg)    
  );    
  
  //Instantiate radix-4 Unit 0
  reg  mux0_block_sync;
  reg  mux0_stage_sync;
  reg  mux0_data_val;
  reg  signed [`MAN_WIDTH-1:0] mux0_data_real;
  reg  signed [`MAN_WIDTH-1:0] mux0_data_imag;
  reg  signed [`EXP_WIDTH-1:0] mux0_data_exp;   
  //reg  [3:0] mux0_ldn_rg;
  wire r4u0_block_sync;
  wire r4u0_next_sync;
  wire r4u0_data_val;
  wire signed [`MAN_WIDTH-1:0] r4u0_data_real;
  wire signed [`MAN_WIDTH-1:0] r4u0_data_imag;
  wire signed [`EXP_WIDTH-1:0] r4u0_data_exp;     
  //wire [3:0] r4u0_ldn_rg;

  always @(*) begin
    if (ldn_rg_i == 4'd3 || ldn_rg_i == 4'd2) begin
      mux0_block_sync = fixed2bfp_block_sync;
      mux0_stage_sync = fixed2bfp_block_sync;
      mux0_data_val   = fixed2bfp_data_val;
      mux0_data_real  = fixed2bfp_data_real;
      mux0_data_imag  = fixed2bfp_data_imag;
      mux0_data_exp   = fixed2bfp_data_exp;   
      //mux0_ldn_rg     = ldn_rg_z1;    
    end
    else begin
      mux0_block_sync = r4u1_block_sync;
      mux0_stage_sync = r4u1_next_sync;
      mux0_data_val   = r4u1_data_val;
      mux0_data_real  = r4u1_data_real;
      mux0_data_imag  = r4u1_data_imag;
      mux0_data_exp   = r4u1_data_exp;   
      //mux0_ldn_rg     = r4u1_ldn_rg;        
    end
  end
      
  radix4_unit0 radix4_unit0(
    .clk_sys        (clk_sys),         
    .rst_sys_n      (rst_sys_n),      
    .block_sync_i   (mux0_block_sync), 
    .stage_sync_i   (mux0_stage_sync),  
    .data_val_i     (mux0_data_val),   
    .data_real_i    (mux0_data_real), 
  	.data_imag_i    (mux0_data_imag),  
  	.data_exp_i     (mux0_data_exp),   
  	.ldn_rg_i       (ldn_rg_i),     
    .block_sync_o   (r4u0_block_sync), 
    .next_sync_o    (r4u0_next_sync),  
    .data_val_o     (r4u0_data_val),   
    .data_real_o    (r4u0_data_real), 
    .data_imag_o    (r4u0_data_imag),  
    .data_exp_o     (r4u0_data_exp)
    //.ldn_rg_o       (r4u0_ldn_rg)   
  );     
  
  //Instantiate radix-2 Unit
  wire r2u_block_sync;
  wire r2u_data_val;
  wire signed [`MAN_WIDTH-1:0] r2u_data_real;
  wire signed [`MAN_WIDTH-1:0] r2u_data_imag;
  wire signed [`EXP_WIDTH-1:0] r2u_data_exp;           
  
  radix2_unit radix2_unit(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n),
    .block_sync_i   (r4u0_block_sync), 
    .stage_sync_i   (r4u0_next_sync), 
    .data_val_i     (r4u0_data_val), 
    .data_real_i    (r4u0_data_real),
  	.data_imag_i    (r4u0_data_imag), 
  	.data_exp_i     (r4u0_data_exp), 
  	.ldn_rg_i       (ldn_rg_i),
    .block_sync_o   (r2u_block_sync), 
    .data_val_o     (r2u_data_val), 
    .data_real_o    (r2u_data_real),
    .data_imag_o    (r2u_data_imag), 
    .data_exp_o     (r2u_data_exp)	
  ); 
  
  //output multiplexer
  reg muxout_block_sync;
  reg muxout_data_val;
  reg signed [`MAN_WIDTH-1:0] muxout_data_real;
  reg signed [`MAN_WIDTH-1:0] muxout_data_imag;
  reg signed [`EXP_WIDTH-1:0] muxout_data_exp;  
  
  always @(*) begin
    if (ldn_rg_i == 4'd11 || ldn_rg_i == 4'd9 || ldn_rg_i == 4'd7 || ldn_rg_i == 4'd5 || ldn_rg_i == 4'd3 ) begin
      muxout_block_sync = r2u_block_sync;
      muxout_data_val   = r2u_data_val;
      muxout_data_real  = r2u_data_real;
      muxout_data_imag  = r2u_data_imag;
      muxout_data_exp   = r2u_data_exp;        
    end
    else begin
      muxout_block_sync = r4u0_block_sync;
      muxout_data_val   = r4u0_data_val;
      muxout_data_real  = r4u0_data_real;
      muxout_data_imag  = r4u0_data_imag;
      muxout_data_exp   = r4u0_data_exp;            
    end
  end  
  
  //Instantiate semi-float point to fixed-point module   
  //reg [3:0] r4u0_ldn_rg_z1;
  //always @(posedge clk_sys) 
  //  r4u0_ldn_rg_z1 <= r4u0_ldn_rg;
    
`ifdef FFT_BIT_REV    
  //Instantiate Bit Reverse module   
  wire bfp2fixed_block_sync;
  wire bfp2fixed_data_val;
  wire signed [`FFT_OUT_WIDTH-1:0] bfp2fixed_data_real;
  wire signed [`FFT_OUT_WIDTH-1:0] bfp2fixed_data_imag;
     
  bfp2fixed bfp2fixed(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n), 
    .block_sync_i   (muxout_block_sync), 
    .data_val_i     (muxout_data_val), 
    .data_real_i    (muxout_data_real), 
    .data_imag_i    (muxout_data_imag),
    .data_exp_i     (muxout_data_exp), 
    .block_sync_o   (bfp2fixed_block_sync), 
    .data_val_o     (bfp2fixed_data_val), 
    .data_real_o    (bfp2fixed_data_real), 
    .data_imag_o    (bfp2fixed_data_imag)
    );  
    
  bit_reverse bit_reverse(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n),
    .block_sync_i   (bfp2fixed_block_sync), 
    .data_val_i     (bfp2fixed_data_val), 
    .data_real_i    (bfp2fixed_data_real),
  	.data_imag_i    (bfp2fixed_data_imag), 
  	.ldn_rg_i       (ldn_rg_i), 
    .block_sync_o   (block_sync_o), 
    .data_val_o     (data_val_o), 
    .data_real_o    (data_real_o),
    .data_imag_o    (data_imag_o) 
    //.ldn_rg_o       (ldn_rg_o)
  );    

`else  
  bfp2fixed bfp2fixed(
    .clk_sys        (clk_sys), 
    .rst_sys_n      (rst_sys_n), 
    .block_sync_i   (muxout_block_sync), 
    .data_val_i     (muxout_data_val), 
    .data_real_i    (muxout_data_real), 
    .data_imag_i    (muxout_data_imag),
    .data_exp_i     (muxout_data_exp), 
    .block_sync_o   (block_sync_o), 
    .data_val_o     (data_val_o), 
    .data_real_o    (data_real_o), 
    .data_imag_o    (data_imag_o)
    );  
    
  //assign ldn_rg_o = r4u0_ldn_rg_z1;
`endif    

  //integer  test_file;
  //always @(posedge clk_sys) begin
  //  if(r4u4_data_val_in == 1'b1)
  //    $fdisplay(test_file,"%d      %d      %d", r4u4_data_real_in, r4u4_data_imag_in, r4u4_data_exp_in);    
  //end  
  //
  //initial
  //  test_file = $fopen(`TEST_FILE);
    
endmodule

