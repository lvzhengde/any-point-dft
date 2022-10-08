/*++
Abstract:
    sample rate conversion
--*/

`include "macros.v"
`include "fixed_point.v"

module src(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  ldn_rg_i,
  trans_len_i,
  din_i, 
	empty_i, 
	almost_empty_i,

	re_o,
	block_sync_o,
	data_val_o,
	data_real_o,
	data_imag_o
  );
  parameter DATA_WIDTH = 2*`FFT_IN_WIDTH;
  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input [3:0]   ldn_rg_i;
  input [10:0]  trans_len_i;
  input [DATA_WIDTH-1:0] din_i; 
	input    empty_i; 
	input    almost_empty_i;
	output reg  re_o;
	output reg  block_sync_o;
	output reg  data_val_o;
	output reg signed [`FFT_IN_WIDTH-1:0] data_real_o;
	output reg signed [`FFT_IN_WIDTH-1:0] data_imag_o;
	
	//Local signals
	reg  [11:0] input_cnt;
	wire [11:0] input_cnt_p1;
	reg  [11:0] output_cnt;
	reg  [11:0] output_cnt_p1;
	reg  block_sync_gen;
	reg  data_val_gen;
	reg  block_sync_z1;
	reg  data_val_z1;
  
  reg  signed [`FFT_IN_WIDTH-1:0] x_r0;  
  reg  signed [`FFT_IN_WIDTH-1:0] x_r1;    
  reg  signed [`FFT_IN_WIDTH-1:0] x_r2;  
  reg  signed [`FFT_IN_WIDTH-1:0] x_r3;    
  reg  signed [`FFT_IN_WIDTH-1:0] x_r4;    
  reg  signed [`FFT_IN_WIDTH-1:0] x_r5;  
  reg  signed [`FFT_IN_WIDTH-1:0] x_r6;      
  reg  signed [`FFT_IN_WIDTH-1:0] x_i0;  
  reg  signed [`FFT_IN_WIDTH-1:0] x_i1;    
  reg  signed [`FFT_IN_WIDTH-1:0] x_i2;  
  reg  signed [`FFT_IN_WIDTH-1:0] x_i3;      
  reg  signed [`FFT_IN_WIDTH-1:0] x_i4;    
  reg  signed [`FFT_IN_WIDTH-1:0] x_i5;  
  reg  signed [`FFT_IN_WIDTH-1:0] x_i6;      
  reg  signed [`FIR_CO_WIDTH-1:0] c0;  
  reg  signed [`FIR_CO_WIDTH-1:0] c1;    
  reg  signed [`FIR_CO_WIDTH-1:0] c2;  
  reg  signed [`FIR_CO_WIDTH-1:0] c3;      
  reg  signed [`FIR_CO_WIDTH-1:0] c4;    
  reg  signed [`FIR_CO_WIDTH-1:0] c5;        
  
  reg  [12:0] cnstDelta; //2.11 unsigned fixed point
  reg  [12:0] acc;
  reg  [12:0] acc_mux;
  
  //Instantiate dual port coefficient ROM 
  parameter LUT_WIDTH = `P_LEN*`FIR_CO_WIDTH; //coefficients 1.13                         
  wire [`L_LDN:0]      rd_addr1;                            
  wire [`L_LDN:0]      rd_addr2;                            
  wire [LUT_WIDTH-1:0] rd_data1;                       
  wire [LUT_WIDTH-1:0] rd_data2;                       
  
  fir_coef_lut fir_coef_lut(
    .rd_addr1_i      (rd_addr1), 
    .rd_addr2_i      (rd_addr2),
    .rd_data1_o      (rd_data1), 
    .rd_data2_o      (rd_data2)
  );
      
  //DCO operation
  always @(*) begin
  	case(ldn_rg_i)
  	  4'd11:    cnstDelta = trans_len_i;         //divide 2048
  	  4'd10:    cnstDelta = (trans_len_i << 1);  //divide 1024
  	  4'd9 :    cnstDelta = (trans_len_i << 2);  //divide 512
  	  4'd8 :    cnstDelta = (trans_len_i << 3);  //divide 256
  	  4'd7 :    cnstDelta = (trans_len_i << 4);  //divide 128
  	  4'd6 :    cnstDelta = (trans_len_i << 5);  //divide 64
  	  4'd5 :    cnstDelta = (trans_len_i << 6);  //divide 32
  	  4'd4 :    cnstDelta = (trans_len_i << 7);  //divide 16
  	  default:  cnstDelta = 0;
  	endcase
  end
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
  	if(!rst_sys_n)
  	  acc <= (1 << 10); //0.5
  	else if(input_cnt < `P_LEN+1)
  		acc <= (1 << 10);
  	else
  	  acc <= acc_mux;
  end
  
  always @(*) begin
  	acc_mux = acc;
  	re_o = (~empty_i);
  	block_sync_gen = 0;
  	data_val_gen = 0;
  	output_cnt_p1 = output_cnt;
  	
  	if(input_cnt >= `P_LEN+1 && acc < (1 << 11) && (output_cnt < (1<<ldn_rg_i))) begin
  	  acc_mux = acc + cnstDelta;
  	  re_o = 1'b0;
  	  
  	  if(input_cnt == `P_LEN+1 && output_cnt == 0)
  	    block_sync_gen = 1;
  	  data_val_gen = 1;
  	    
  	  output_cnt_p1 = output_cnt + 1;
  	end 
  	 	
  	if(acc_mux >= (1 << 11) && (~empty_i)) begin   //need request a new sample from fifo
  	  acc_mux = acc_mux - (1 << 11);
  	  re_o = 1'b1;
  	end
  end
  
  //output sample counter
  always @(posedge clk_sys or negedge rst_sys_n)
    if (!rst_sys_n)
    	output_cnt <= 0;
    else if(input_cnt < `P_LEN+1 || block_sync_i == 1'b1)
      output_cnt <= 0;
    else
    	output_cnt <= output_cnt_p1;  

  //input sample counter
  always @(posedge clk_sys or negedge rst_sys_n)
    if (!rst_sys_n)
    	input_cnt <= 0;
    else
    	input_cnt <= input_cnt_p1;
   
   assign input_cnt_p1 = (block_sync_i == 1'b1) ? 0 : (re_o == 1'b1) ? input_cnt+1 : input_cnt; 
    

  //delay line operation
  always @(posedge clk_sys or negedge rst_sys_n) begin 
  	if(!rst_sys_n) begin
  	  x_r0 <= 0;
  	  x_i0 <= 0;  	
  	  x_r1 <= 0;
  	  x_i1 <= 0;  	  	    
  	  x_r2 <= 0;
  	  x_i2 <= 0;  	
  	  x_r3 <= 0;
  	  x_i3 <= 0; 
  	  x_r4 <= 0;
  	  x_i4 <= 0;  	  	    
  	  x_r5 <= 0;
  	  x_i5 <= 0;  	
  	  x_r6 <= 0;
  	  x_i6 <= 0;   	    
  	end
  	else if(re_o == 1'b1) begin
  		x_r0 <= din_i[DATA_WIDTH-1:`FFT_IN_WIDTH];
  		x_i0 <= din_i[`FFT_IN_WIDTH-1:0];
  		x_r1 <= x_r0;
      x_i1 <= x_i0;
      x_r2 <= x_r1;
      x_i2 <= x_i1;
      x_r3 <= x_r2;
      x_i3 <= x_i2;
      x_r4 <= x_r3;
      x_i4 <= x_i3;
      x_r5 <= x_r4;
      x_i5 <= x_i4;
      x_r6 <= x_r5;
      x_i6 <= x_i5;
  	end
  end
    
  wire [17:0] ampAcc = (acc << `L_LDN);     //7.11
  wire [4:0]  posCoefInt = ampAcc[15:11];   //Integer part
  wire [10:0] posCoefDec = ampAcc[10:0];    //fractional part
  
  wire [12:0] acc_next = (acc_mux < (1 << 11)) ? acc_mux : acc_mux-1;
  wire [17:0] ampAcc_next = (acc_next << `L_LDN);     //7.11
  wire [4:0]  posCoefInt_next = ampAcc_next[15:11];   //Integer part   
  wire [10:0] posCoefDec_next = ampAcc_next[10:0];    //fractional part  
  
  assign rd_addr1 = {1'b0, posCoefInt_next};                            
  assign rd_addr2 = rd_addr1+1;  
  
  reg signed [`FIR_CO_WIDTH-1:0] c1_0;  
  reg signed [`FIR_CO_WIDTH-1:0] c1_1;  
  reg signed [`FIR_CO_WIDTH-1:0] c1_2;  
  reg signed [`FIR_CO_WIDTH-1:0] c1_3;  
  reg signed [`FIR_CO_WIDTH-1:0] c1_4;  
  reg signed [`FIR_CO_WIDTH-1:0] c1_5;  
  reg signed [`FIR_CO_WIDTH-1:0] c2_0;  
  reg signed [`FIR_CO_WIDTH-1:0] c2_1;  
  reg signed [`FIR_CO_WIDTH-1:0] c2_2;  
  reg signed [`FIR_CO_WIDTH-1:0] c2_3;  
  reg signed [`FIR_CO_WIDTH-1:0] c2_4;  
  reg signed [`FIR_CO_WIDTH-1:0] c2_5;    
  
  //special case for `P_LEN = 6
  always @(*) begin
    {c1_5, c1_4, c1_3, c1_2, c1_1, c1_0} = rd_data1;
    {c2_5, c2_4, c2_3, c2_2, c2_1, c2_0} = rd_data2;
  end
  
  //coefficient interpolation     
    reg signed [`FIR_CO_WIDTH:0]      diff_c0;     
    reg signed [`FIR_CO_WIDTH:0]      diff_c1;    
    reg signed [`FIR_CO_WIDTH:0]      diff_c2;     
    reg signed [`FIR_CO_WIDTH:0]      diff_c3;    
    reg signed [`FIR_CO_WIDTH:0]      diff_c4;     
    reg signed [`FIR_CO_WIDTH:0]      diff_c5;    
    reg signed [`FIR_CO_WIDTH+11:0]   mul_c0;    
    reg signed [`FIR_CO_WIDTH+11:0]   mul_c1;    
    reg signed [`FIR_CO_WIDTH+11:0]   mul_c2;    
    reg signed [`FIR_CO_WIDTH+11:0]   mul_c3;    
    reg signed [`FIR_CO_WIDTH+11:0]   mul_c4;    
    reg signed [`FIR_CO_WIDTH+11:0]   mul_c5;    
    reg signed [`FIR_CO_WIDTH+12:0]   temp_c0;      
    reg signed [`FIR_CO_WIDTH+12:0]   temp_c1;     
    reg signed [`FIR_CO_WIDTH+12:0]   temp_c2; 
    reg signed [`FIR_CO_WIDTH+12:0]   temp_c3;      
    reg signed [`FIR_CO_WIDTH+12:0]   temp_c4;     
    reg signed [`FIR_CO_WIDTH+12:0]   temp_c5;             
    reg signed [`FIR_CO_WIDTH-1:0]    coef0;    
    reg signed [`FIR_CO_WIDTH-1:0]    coef1;     
    reg signed [`FIR_CO_WIDTH-1:0]    coef2;         
    reg signed [`FIR_CO_WIDTH-1:0]    coef3;             
    reg signed [`FIR_CO_WIDTH-1:0]    coef4;         
    reg signed [`FIR_CO_WIDTH-1:0]    coef5;    
          
  always @(*) begin : COEF_INP
    reg signed [`FIR_CO_WIDTH+12:0] temp;
    
    diff_c0 = c2_0 - c1_0;
    mul_c0  = $signed({1'b0,posCoefDec_next})*diff_c0;    //1.11*2.13
    temp_c0 = (c1_0 <<< 11) + mul_c0;
    `SYMRND(temp_c0, temp_c0, 11);
    temp = temp_c0;
    coef0 = temp[`FIR_CO_WIDTH-1:0];   

    diff_c1 = c2_1 - c1_1;
    mul_c1  = $signed({1'b0,posCoefDec_next})*diff_c1;    //1.11*2.13
    temp_c1 = (c1_1 <<< 11) + mul_c1;
    `SYMRND(temp_c1, temp_c1, 11);
    temp = temp_c1;
    coef1 = temp[`FIR_CO_WIDTH-1:0];        
    
    diff_c2 = c2_2 - c1_2;
    mul_c2  = $signed({1'b0,posCoefDec_next})*diff_c2;    //1.11*2.13
    temp_c2 = (c1_2 <<< 11) + mul_c2;
    `SYMRND(temp_c2, temp_c2, 11);
    temp = temp_c2;
    coef2 = temp[`FIR_CO_WIDTH-1:0];            
    
    diff_c3 = c2_3 - c1_3;
    mul_c3  = $signed({1'b0,posCoefDec_next})*diff_c3;    //1.11*2.13
    temp_c3 = (c1_3 <<< 11) + mul_c3;
    `SYMRND(temp_c3, temp_c3, 11);
    temp = temp_c3;
    coef3 = temp[`FIR_CO_WIDTH-1:0];       

    diff_c4 = c2_4 - c1_4;
    mul_c4  = $signed({1'b0,posCoefDec_next})*diff_c4;    //1.11*2.13
    temp_c4 = (c1_4 <<< 11) + mul_c4;
    `SYMRND(temp_c4, temp_c4, 11);
    temp = temp_c4;
    coef4 = temp[`FIR_CO_WIDTH-1:0];                   
    
    diff_c5 = c2_5 - c1_5;
    mul_c5  = $signed({1'b0,posCoefDec_next})*diff_c5;    //1.11*2.13
    temp_c5 = (c1_5 <<< 11) + mul_c5;
    `SYMRND(temp_c5, temp_c5, 11);
    temp = temp_c5;
    coef5 = temp[`FIR_CO_WIDTH-1:0];                       
  end 
  
  always @(posedge clk_sys or negedge rst_sys_n) begin : COEF_UP   
    if(!rst_sys_n) begin
    	c0 <= 0;
    	c1 <= 0;
    	c2 <= 0;
    	c3 <= 0;
    	c4 <= 0;
    	c5 <= 0;
    end
    else begin  // output_cnt != output_cnt_p1
    	c0 <= coef0;
    	c1 <= coef1;
    	c2 <= coef2;
    	c3 <= coef3;
    	c4 <= coef4;
    	c5 <= coef5;    	
    end
  end
  
  //
  //FIR operation
  //

  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_r_mul0;  
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_r_mul1;    
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_r_mul2;  
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_r_mul3;    
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_r_mul4;  
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_r_mul5;    

  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_i_mul0;
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_i_mul1;
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_i_mul2;
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_i_mul3;
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_i_mul4;
  reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] x_i_mul5;
            
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_0;  
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_1;  
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_2;  
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_3;  
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_4;  
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_5;    
      
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_0;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_1;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_2;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_3;    
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_4;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_5;    
         
  always @(*) begin : MULTIPY //.FFT_IN_PTPOS*1.(`FIR_CO_WIDTH-1)
    reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] temp_r;
    reg signed [`FFT_IN_WIDTH+`FIR_CO_WIDTH-2:0] temp_i;
    
    x_r_mul0 = c0 * x_r1;
    x_i_mul0 = c0 * x_i1;
    `SYMRND(x_r_mul0, x_r_mul0, (`FIR_CO_WIDTH-1));     
    `SYMRND(x_i_mul0, x_i_mul0, (`FIR_CO_WIDTH-1));  
    temp_r = x_r_mul0;
    temp_i = x_i_mul0;
    x_r_sum0_0 = temp_r[`FFT_IN_WIDTH-1:0];
    x_i_sum0_0 = temp_i[`FFT_IN_WIDTH-1:0];    
    
    x_r_mul1 = c1 * x_r2;
    x_i_mul1 = c1 * x_i2;
    `SYMRND(x_r_mul1, x_r_mul1, (`FIR_CO_WIDTH-1));     
    `SYMRND(x_i_mul1, x_i_mul1, (`FIR_CO_WIDTH-1));  
    temp_r = x_r_mul1;
    temp_i = x_i_mul1;
    x_r_sum0_1 = temp_r[`FFT_IN_WIDTH-1:0];
    x_i_sum0_1 = temp_i[`FFT_IN_WIDTH-1:0];
    
    x_r_mul2 = c2 * x_r3;
    x_i_mul2 = c2 * x_i3;
    `SYMRND(x_r_mul2, x_r_mul2, (`FIR_CO_WIDTH-1));     
    `SYMRND(x_i_mul2, x_i_mul2, (`FIR_CO_WIDTH-1));  
    temp_r = x_r_mul2;
    temp_i = x_i_mul2;
    x_r_sum0_2 = temp_r[`FFT_IN_WIDTH-1:0];
    x_i_sum0_2 = temp_i[`FFT_IN_WIDTH-1:0]; 
    
    x_r_mul3 = c3 * x_r4;
    x_i_mul3 = c3 * x_i4;
    `SYMRND(x_r_mul3, x_r_mul3, (`FIR_CO_WIDTH-1));     
    `SYMRND(x_i_mul3, x_i_mul3, (`FIR_CO_WIDTH-1));  
    temp_r = x_r_mul3;
    temp_i = x_i_mul3;
    x_r_sum0_3 = temp_r[`FFT_IN_WIDTH-1:0];
    x_i_sum0_3 = temp_i[`FFT_IN_WIDTH-1:0]; 
    
    x_r_mul4 = c4 * x_r5;
    x_i_mul4 = c4 * x_i5;
    `SYMRND(x_r_mul4, x_r_mul4, (`FIR_CO_WIDTH-1));     
    `SYMRND(x_i_mul4, x_i_mul4, (`FIR_CO_WIDTH-1));  
    temp_r = x_r_mul4;
    temp_i = x_i_mul4;
    x_r_sum0_4 = temp_r[`FFT_IN_WIDTH-1:0];
    x_i_sum0_4 = temp_i[`FFT_IN_WIDTH-1:0];     
                             
    x_r_mul5 = c5 * x_r6;
    x_i_mul5 = c5 * x_i6;
    `SYMRND(x_r_mul5, x_r_mul5, (`FIR_CO_WIDTH-1));     
    `SYMRND(x_i_mul5, x_i_mul5, (`FIR_CO_WIDTH-1));  
    temp_r = x_r_mul5;
    temp_i = x_i_mul5;
    x_r_sum0_5 = temp_r[`FFT_IN_WIDTH-1:0];
    x_i_sum0_5 = temp_i[`FFT_IN_WIDTH-1:0];     
  end
  
  //correction factor (x(n+1)-x(n-P+1))*posCoefDec*c0(0)
  //c0(0)=-0.00052229, special case fixed point 1.13
  reg signed [`FFT_IN_WIDTH:0]    x_r_diff;
  reg signed [`FFT_IN_WIDTH:0]    x_i_diff;
  reg signed [`FFT_IN_WIDTH+11:0] delta0_r;
  reg signed [`FFT_IN_WIDTH+11:0] delta0_i;  
  reg signed [`FFT_IN_WIDTH-1:0]  delta1_r;
  reg signed [`FFT_IN_WIDTH-1:0]  delta1_i;    
  reg signed [`FFT_IN_WIDTH+1:0]  delta2_r;
  reg signed [`FFT_IN_WIDTH+1:0]  delta2_i;    
  reg signed [`FFT_IN_WIDTH-1:0]  delta_out_r;
  reg signed [`FFT_IN_WIDTH-1:0]  delta_out_i;   
  
  always @(*) begin
    x_r_diff = x_r6 - x_r0;
    x_i_diff = x_i6 - x_i0;
    
    delta0_r = x_r_diff * $signed({1'b0,posCoefDec});
    delta0_i = x_i_diff * $signed({1'b0,posCoefDec});  
    `SYMRND(delta0_r, delta0_r, 11);     
    `SYMRND(delta0_i, delta0_i, 11);  
    delta1_r = delta0_r[`FFT_IN_WIDTH-1:0];
    delta1_i = delta0_i[`FFT_IN_WIDTH-1:0];  
    
    delta2_r = (delta1_r <<< 2);
    delta2_i = (delta1_i <<< 2);  
    `SYMRND(delta2_r, delta2_r, (`FIR_CO_WIDTH-1));     
    `SYMRND(delta2_i, delta2_i, (`FIR_CO_WIDTH-1));  
    
    if(posCoefInt < ((1<<`L_LDN)-1)) begin
      delta_out_r = 0;
      delta_out_i = 0;
    end
    else begin
      delta_out_r = delta2_r[`FFT_IN_WIDTH-1:0];
      delta_out_i = delta2_i[`FFT_IN_WIDTH-1:0];
    end     
  end 
  
  //registered output of multiplication
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_0_z1;          
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_1_z1;      
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_2_z1;          
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_3_z1;           
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_4_z1;          
  reg signed [`FFT_IN_WIDTH-1:0] x_r_sum0_5_z1;       
      
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_0_z1;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_1_z1;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_2_z1;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_3_z1;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_4_z1;     
  reg signed [`FFT_IN_WIDTH-1:0] x_i_sum0_5_z1;     
        
  reg signed [`FFT_IN_WIDTH-1:0] delta_out_r_z1;
  reg signed [`FFT_IN_WIDTH-1:0] delta_out_i_z1;    
      
  always @(posedge clk_sys or negedge rst_sys_n) begin : REG_1
    if(!rst_sys_n) begin
      delta_out_r_z1 <= 0;
      delta_out_i_z1 <= 0; 
      
      x_r_sum0_0_z1 <= 0;
      x_i_sum0_0_z1 <= 0;       
      x_r_sum0_1_z1 <= 0;
      x_i_sum0_1_z1 <= 0;       
      x_r_sum0_2_z1 <= 0;
      x_i_sum0_2_z1 <= 0;       
      x_r_sum0_3_z1 <= 0;
      x_i_sum0_3_z1 <= 0;      
      x_r_sum0_4_z1 <= 0;
      x_i_sum0_4_z1 <= 0;    
      x_r_sum0_5_z1 <= 0;
      x_i_sum0_5_z1 <= 0;  
      
      block_sync_z1 <= 0;
      data_val_z1 <= 0;
    end
    else begin
      delta_out_r_z1 <= delta_out_r;
      delta_out_i_z1 <= delta_out_i; 
      
      x_r_sum0_0_z1 <= x_r_sum0_0;
      x_i_sum0_0_z1 <= x_i_sum0_0;       
      x_r_sum0_1_z1 <= x_r_sum0_1;
      x_i_sum0_1_z1 <= x_i_sum0_1;       
      x_r_sum0_2_z1 <= x_r_sum0_2;
      x_i_sum0_2_z1 <= x_i_sum0_2;       
      x_r_sum0_3_z1 <= x_r_sum0_3;
      x_i_sum0_3_z1 <= x_i_sum0_3;      
      x_r_sum0_4_z1 <= x_r_sum0_4;
      x_i_sum0_4_z1 <= x_i_sum0_4;    
      x_r_sum0_5_z1 <= x_r_sum0_5;
      x_i_sum0_5_z1 <= x_i_sum0_5;        
      
      block_sync_z1 <= block_sync_gen;
      data_val_z1 <= data_val_gen;    
    end
  end
  
  //
  //adder tree
  //special case for `P_LEN = 6
  //
  wire signed [`FFT_IN_WIDTH:0]   add0_level0_r, add1_level0_r, add2_level0_r; 
  wire signed [`FFT_IN_WIDTH:0]   add0_level0_i, add1_level0_i, add2_level0_i;  
  wire signed [`FFT_IN_WIDTH+1:0] add0_level1_r, add1_level1_r; 
  wire signed [`FFT_IN_WIDTH+1:0] add0_level1_i, add1_level1_i;   
  wire signed [`FFT_IN_WIDTH+2:0] add0_level2_r; 
  wire signed [`FFT_IN_WIDTH+2:0] add0_level2_i; 
  
  //level 0
  assign add0_level0_r = x_r_sum0_0_z1 + x_r_sum0_1_z1;
  assign add0_level0_i = x_i_sum0_0_z1 + x_i_sum0_1_z1;
  assign add1_level0_r = x_r_sum0_2_z1 + x_r_sum0_3_z1;
  assign add1_level0_i = x_i_sum0_2_z1 + x_i_sum0_3_z1;
  assign add2_level0_r = x_r_sum0_4_z1 + x_r_sum0_5_z1;
  assign add2_level0_i = x_i_sum0_4_z1 + x_i_sum0_5_z1;
  
  //level 1
  assign add0_level1_r = add0_level0_r + add1_level0_r; 
  assign add0_level1_i = add0_level0_i + add1_level0_i; 
  assign add1_level1_r = add2_level0_r + delta_out_r_z1; 
  assign add1_level1_i = add2_level0_i + delta_out_i_z1;   
  
  //level 2
  assign add0_level2_r = add0_level1_r + add1_level1_r; 
  assign add0_level2_i = add0_level1_i + add1_level1_i;   
  
  reg signed [`FFT_IN_WIDTH+2:0] data_real; 
  reg signed [`FFT_IN_WIDTH+2:0] data_imag;  
  
  always @(*) begin
    data_real = add0_level2_r;
    data_imag = add0_level2_i;
    `SYMSAT(data_real, `FFT_IN_WIDTH);
    `SYMSAT(data_imag, `FFT_IN_WIDTH);         
  end
  
  //output results    
  always @(posedge clk_sys or negedge rst_sys_n) begin   
    if(!rst_sys_n) begin
      block_sync_o <= 0;
      data_val_o <= 0;
      data_real_o <= 0;
      data_imag_o <= 0;
    end
    else begin  
      data_real_o <= 0;
      data_imag_o <= 0;
      block_sync_o <= block_sync_z1;
      data_val_o <= data_val_z1;
      if(data_val_z1 == 1'b1) begin
        data_real_o <= data_real[`FFT_IN_WIDTH-1:0];
        data_imag_o <= data_imag[`FFT_IN_WIDTH-1:0];
      end
    end
  end
                              
endmodule
