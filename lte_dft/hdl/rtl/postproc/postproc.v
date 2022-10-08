/*++
Abstract:
    lte dft post processing
--*/

`include "macros.v"
`include "fixed_point.v"

module postproc(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i,
  data_imag_i,
  ldn_rg_i,
  trans_len_i,  
  block_sync_o, 
  data_val_o, 
  data_real_o, 
  data_imag_o,
  trans_len_o,
  data_index_o
  );
  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input    data_val_i;
  input signed [`FFT_OUT_WIDTH-1:0] data_real_i;
  input signed [`FFT_OUT_WIDTH-1:0] data_imag_i;
  input [3:0]   ldn_rg_i;  
  input [11:0]  trans_len_i;
  output reg block_sync_o; 
  output reg data_val_o; 
  output reg signed [`FFT_OUT_WIDTH-1:0] data_real_o; 
  output reg signed [`FFT_OUT_WIDTH-1:0] data_imag_o;
  output reg [11:0] trans_len_o;  
  output reg [11:0] data_index_o;
  
  //Local signals  
  reg  [11:0] sym_in_cnt;
  wire [11:0] sym_in_cnt_p1;
  reg  [11:0] data_index;
  reg  block_sync_z1;
  reg  data_val_z1;
  reg  signed [`FFT_OUT_WIDTH-1:0] data_real_z1;
  reg  signed [`FFT_OUT_WIDTH-1:0] data_imag_z1; 
  
  reg  data_valid;  
  reg  data_valid_z1;
  
  //instantiate look up table for frequency compensation
  wire [13:0]     rom_addr;
  wire [2*13-1:0] rom_data;
  freq_comp_rom freq_comp_rom(
    .rom_addr       (rom_addr),
    .rom_data       (rom_data)
  );
  
  always @(posedge clk_sys) begin
    block_sync_z1 <= block_sync_i;
    data_val_z1 <= data_val_i;
    data_real_z1 <= data_real_i;
    data_imag_z1 <= data_imag_i;  
  end
    
  //generate data index and address for look up table
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)
      sym_in_cnt <= 0;
    else if(data_val_i)
      sym_in_cnt <= sym_in_cnt_p1;
  end
  
  assign sym_in_cnt_p1 = (block_sync_i) ? 0 : sym_in_cnt + 1;

  wire [9:0]  addr_offset;
  reg [13:0] addr_base; 
  reg  [11:0] data_index_p1;
  wire [11:0] rev_sym_cnt_p1;
  wire [11:0] N_div_2 = (trans_len_i >> 1);
  reg  [11:0] M;
  wire [11:0] N = trans_len_i;
  wire [11:0] mid_point = N_div_2 + M - N;

	always @(*) begin
	  case(ldn_rg_i)
	    4'd11:   M = 12'd2048;     //2048-point
	    4'd10:   M = 12'd1024;     //1024-point
	    4'd9:    M = 12'd512;      //512-point
	    4'd8:    M = 12'd256;      //256-point
	    4'd7:    M = 12'd128;      //128-point
	    4'd6:    M = 12'd64;       //64-point
	    4'd5:    M = 12'd32;       //32-point
	    4'd4:    M = 12'd16;       //16-point
	    default: M = 12'd2048;
	  endcase
	end 
	
	always @(*) begin
	  case(N)
	    12'd12    : addr_base = 0;
	    12'd24    : addr_base = 7;
	    12'd36    : addr_base = 20;
      12'd48    : addr_base = 39;
      12'd60    : addr_base = 64;
      12'd72    : addr_base = 95;
      12'd96    : addr_base = 132;
      12'd108   : addr_base = 181;
      12'd120   : addr_base = 236;
      12'd144   : addr_base = 297;
      12'd180   : addr_base = 370;
      12'd192   : addr_base = 461;
      12'd216   : addr_base = 558;
      12'd240   : addr_base = 667;
      12'd288   : addr_base = 788;
      12'd300   : addr_base = 933;
      12'd324   : addr_base = 1084;
      12'd360   : addr_base = 1247;
      12'd384   : addr_base = 1428;
      12'd432   : addr_base = 1621;
      12'd480   : addr_base = 1838;
      12'd540   : addr_base = 2079;
      12'd576   : addr_base = 2350;
      12'd600   : addr_base = 2639;
      12'd648   : addr_base = 2940;
      12'd720   : addr_base = 3265;
      12'd768   : addr_base = 3626;
      12'd864   : addr_base = 4011;
      12'd900   : addr_base = 4444;
      12'd960   : addr_base = 4895;
      12'd972   : addr_base = 5376;
      12'd1080  : addr_base = 5863;
      12'd1152  : addr_base = 6404;
      12'd1200  : addr_base = 6981;
      12'd1296  : addr_base = 7582;
      12'd1536  : addr_base = 8231;
      default   : addr_base = 0;
    endcase
  end
	    
`ifdef FFT_BIT_REV        //input data in natural order
  always @(*) begin
    data_valid = 1'b1;
    
    if(sym_in_cnt_p1 <= N_div_2)
      data_index_p1 = sym_in_cnt_p1;
    else if(sym_in_cnt_p1 > mid_point)
      data_index_p1 = (sym_in_cnt_p1 + N) - M;
    else begin
      data_index_p1 = 0;
      data_valid = 1'b0;
    end
  end  
  
  assign addr_offset = (data_index_p1 <= N_div_2) ? data_index_p1 : N - data_index_p1;
  assign rom_addr = addr_base + {3'd0, addr_offset};
  
`else                     //input data in bit reverse order
  assign rev_sym_cnt_p1 = revbin_permute(sym_in_cnt_p1, ldn_rg_i);
  
  always @(*) begin
    data_valid = 1'b1;
    
    if(rev_sym_cnt_p1 <= N_div_2)
      data_index_p1 = rev_sym_cnt_p1;
    else if(rev_sym_cnt_p1 > mid_point)
      data_index_p1 = (rev_sym_cnt_p1 + N) - M;
    else begin
      data_index_p1 = 0;
      data_valid = 1'b0;
    end
  end  
  
  assign addr_offset = (data_index_p1 <= N_div_2) ? data_index_p1 : N - data_index_p1;
  assign rom_addr = addr_base + {3'd0, addr_offset};  
`endif

  //frequency compensation
  reg signed [12:0] comp_real;    //S3.10
  reg signed [12:0] comp_imag;
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n) begin
    	comp_real <= 0;
    	comp_imag <= 0;
    end
    else begin
    	if(data_index_p1 <= N_div_2) begin
    		comp_real <= $signed(rom_data[12:0]);
    		comp_imag <= $signed(rom_data[25:13]);
      end
      else begin
     		comp_real <= $signed(rom_data[12:0]);
    		comp_imag <= -$signed(rom_data[25:13]); 
    	end
    end    		
  end

  //complex multiplication
  reg signed [`FFT_OUT_WIDTH+12:0] temp1, temp2, temp3;
  reg signed [`FFT_OUT_WIDTH-1:0]  data_real, data_imag;  
  always @(*) begin
	  temp1 = (data_real_z1 + data_imag_z1) * comp_real; 
	  temp2 = data_imag_z1 * (comp_imag + comp_real);
	  temp3 = data_real_z1 * (comp_imag - comp_real);	  
	  
    `SYMRND(temp1, temp1, 10);
    `SYMRND(temp2, temp2, 10);
    `SYMRND(temp3, temp3, 10);
    
    //should make sure no overflow occurs
	  data_real = temp1 - temp2;
	  data_imag = temp1 + temp3;	       	
  end

  //output results
  always @(posedge clk_sys)  begin
    data_valid_z1   <= data_valid;
    data_index      <= data_index_p1;
  end
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
  	if(!rst_sys_n) begin
  		block_sync_o <= 0;
  		data_val_o   <= 0;
  		data_real_o  <= 0;
  		data_imag_o  <= 0;
  		trans_len_o  <= 0;
  		data_index_o <= 0;
  	end
  	else begin
 		  block_sync_o <= block_sync_z1;
 		  data_val_o   <= data_val_z1 & data_valid_z1;  	
 		  trans_len_o  <= trans_len_i;
 		  data_index_o <= data_index;	
  		if(M != N) begin  //for non-2^n point dft
  			data_real_o <= data_real;
  			data_imag_o <= data_imag;
  		end
  		else begin       //for 2^n FFT
  			data_real_o <= data_real_z1;
  			data_imag_o <= data_imag_z1;
  		end
    end
  end

  //function for bit reverse
  function [10:0] revbin_permute;
  input [10:0] pos;
  input [3:0]  ldn;
  reg   [10:0] addr;
    begin
      addr = 11'd0;
      case (ldn)
        4'd11: 
            {addr[10], addr[9], addr[8], addr[7], addr[6], addr[5], addr[4], addr[3], addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2], pos[3], pos[4], pos[5], pos[6], pos[7], pos[8], pos[9], pos[10]};
        4'd10:
            {addr[9], addr[8], addr[7], addr[6], addr[5], addr[4], addr[3], addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2], pos[3], pos[4], pos[5], pos[6], pos[7], pos[8], pos[9]};           
        4'd9:
            {addr[8], addr[7], addr[6], addr[5], addr[4], addr[3], addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2], pos[3], pos[4], pos[5], pos[6], pos[7], pos[8]};  
        4'd8:
            {addr[7], addr[6], addr[5], addr[4], addr[3], addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2], pos[3], pos[4], pos[5], pos[6], pos[7]}; 
        4'd7:
            {addr[6], addr[5], addr[4], addr[3], addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2], pos[3], pos[4], pos[5], pos[6]};  
        4'd6:
            {addr[5], addr[4], addr[3], addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2], pos[3], pos[4], pos[5]};  
        4'd5:
            {addr[4], addr[3], addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2], pos[3], pos[4]};   
        4'd4:
            {addr[3], addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2], pos[3]};                                                                              
      endcase
      
      revbin_permute = addr;
    end
  endfunction
endmodule

