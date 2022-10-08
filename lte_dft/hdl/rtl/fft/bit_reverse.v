/*++
Abstract:
  pipeline fft bit reverse module
--*/

`include "macros.v"
`include "fixed_point.v"

module bit_reverse(
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
  parameter RAM_WIDTH = 2*`FFT_OUT_WIDTH;
 	input clk_sys;
	input rst_sys_n;	
  input block_sync_i;
  input data_val_i;
	input signed [`FFT_OUT_WIDTH-1:0] data_real_i;
	input signed [`FFT_OUT_WIDTH-1:0] data_imag_i;	
	input [3:0] ldn_rg_i;
	output reg block_sync_o;
	output reg data_val_o;
	output reg signed [`FFT_OUT_WIDTH-1:0] data_real_o;
	output reg signed [`FFT_OUT_WIDTH-1:0] data_imag_o;
	//output reg [3:0] ldn_rg_o;
	
	//internal signals
	reg  [10:0]     input_pos_sig;
	wire [10:0]     input_pos_p1;
	reg  [10:0]     output_pos_sig;
	wire [10:0]     output_pos_p1;
	reg data_val_z1;
	reg signed [`FFT_OUT_WIDTH-1:0]     data_real_z1;
	reg signed [`FFT_OUT_WIDTH-1:0]     data_imag_z1;
	reg    rev_input_sig;
	reg    rev_output_sig;
	reg    rev_input_z1;
	reg    rev_input_z2;
	reg    start_output_sig;
	reg    output_req_sig;
	//reg [3:0]   ldn_rg_i_z1;
	
	//Instantiate bit reverse RAM
	reg  wr_en;    //active low
	reg  [10:0] wr_addr;
	reg  [RAM_WIDTH-1:0] wr_data;
	wire [10:0] rd_addr;
	wire [RAM_WIDTH-1:0] rd_data;
	
	bit_rev_ram bit_rev_ram(
	  .clk_sys       (clk_sys),
	  .wr_en         (wr_en)  ,
	  .wr_addr       (wr_addr),
	  .wr_data       (wr_data),
	  .rd_addr       (rd_addr),
	  .rd_data       (rd_data)
	);
	
	always @(posedge clk_sys or negedge rst_sys_n) begin
	  if (!rst_sys_n) begin
	    data_val_z1  <= 1'b0;
	    data_real_z1 <= 0;
	    data_imag_z1 <= 0;
	    rev_input_z1 <= 1'b0;
	    rev_input_z2 <= 1'b0;
	  end
	  else begin
	    data_val_z1  <= data_val_i;
	    data_real_z1 <= data_real_i;
	    data_imag_z1 <= data_imag_i;
	    rev_input_z1 <= rev_input_sig;
	    rev_input_z2 <= rev_input_z1;
	  end  
	end
	
	//always @(posedge clk_sys or negedge rst_sys_n) 
	//  if (!rst_sys_n)
	//    ldn_rg_i_z1 <= 0;
	//  else if (block_sync_i == 1'b1)
	//    ldn_rg_i_z1 <= ldn_rg_i;

  //handle input processing
  reg [11:0] data_point;
  always @(*) begin
    case (ldn_rg_i)
      4'd11:   data_point = 2048;
      4'd10:   data_point = 1024;
      4'd9:    data_point = 512;
      4'd8:    data_point = 256;
      4'd7:    data_point = 128;
      4'd6:    data_point = 64;
      4'd5:    data_point = 32;
      4'd4:    data_point = 16;
      4'd3:    data_point = 8;
      4'd2:    data_point = 4;
      default: data_point = 2048;
    endcase
  end  
  
  //reg [11:0] data_point_in;
  //always @(*) begin
  //  case (ldn_rg_i)
  //    4'd11:   data_point_in = 2048;
  //    4'd10:   data_point_in = 1024;
  //    4'd9:    data_point_in = 512;
  //    4'd8:    data_point_in = 256;
  //    4'd7:    data_point_in = 128;
  //    4'd6:    data_point_in = 64;
  //    4'd5:    data_point_in = 32;
  //    4'd4:    data_point_in = 16;
  //    4'd3:    data_point_in = 8;
  //    4'd2:    data_point_in = 4;
  //    default: data_point_in = 2048;
  //  endcase
  //end
  
  assign input_pos_p1 = (block_sync_i == 1'b1) ? 0 : ((data_val_i == 1'b1) ? input_pos_sig + 1 : input_pos_sig);
  
  always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)
      input_pos_sig <= 0;
    else
      input_pos_sig <= input_pos_p1;
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      rev_input_sig    <= 1'b0;
      start_output_sig <= 1'b0;
      wr_en            <= 1'b1;
      wr_addr          <= 0;
      wr_data          <= 0;
    end
    else begin  
      start_output_sig <= 1'b0;
      wr_en <= 1'b1;
        
      if (input_pos_sig == (data_point-2) && input_pos_p1 == (data_point-1)) begin
        rev_input_sig    <= ~rev_input_sig;
        start_output_sig <= 1'b1;
      end
      
      if (data_val_z1 == 1'b1) begin
        if (rev_input_z2 == 1'b0) begin  
          wr_en   <= 1'b0;
          wr_addr <= input_pos_sig[10:0];
          wr_data <= {data_real_z1, data_imag_z1};
        end
        else begin
          wr_en <= 1'b0;
          wr_addr <= revbin_permute(input_pos_sig[10:0], ldn_rg_i);
          wr_data <= {data_real_z1, data_imag_z1};
        end     
      end
        
    end
  end
  
  //handle output processing
  //reg [11:0] data_point_out;
  //always @(*) begin
  //  case (ldn_rg_i)
  //    4'd11:   data_point_out = 2048;
  //    4'd10:   data_point_out = 1024;
  //    4'd9:    data_point_out = 512;
  //    4'd8:    data_point_out = 256;
  //    4'd7:    data_point_out = 128;
  //    4'd6:    data_point_out = 64;
  //    4'd5:    data_point_out = 32;
  //    4'd4:    data_point_out = 16;
  //    4'd3:    data_point_out = 8;
  //    4'd2:    data_point_out = 4;
  //    default: data_point_out = 2048;
  //  endcase
  //end
  
  assign rd_addr = (rev_output_sig==1'b1) ? revbin_permute(output_pos_p1, ldn_rg_i) : output_pos_p1;
  
  assign output_pos_p1 = ((output_pos_sig > 0 && output_pos_sig < (data_point-1)) || (output_req_sig == 1'b1)) ? 
                           (output_pos_sig + 1) : 0;
  
  always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)
      output_pos_sig <= 0;
    else
      output_pos_sig <= output_pos_p1;
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      rev_output_sig <= 1'b0;
      output_req_sig <= 1'b0;
      block_sync_o   <= 1'b0;
      data_val_o     <= 1'b0;
      data_real_o    <= 0;
      data_imag_o    <= 0;
      //ldn_rg_o       <= 4'd0;
    end
    else begin
      if (start_output_sig == 1'b1) begin
        rev_output_sig <= rev_input_sig;
        output_req_sig <= 1'b1;
        //ldn_rg_o       <= ldn_rg_i_z1;
      end
      
      //default output values
      block_sync_o <= 1'b0;
      data_val_o   <= 1'b0;
      data_real_o  <= rd_data[RAM_WIDTH-1:`FFT_OUT_WIDTH];
      data_imag_o  <= rd_data[`FFT_OUT_WIDTH-1:0];
      
      if (output_req_sig == 1'b1) begin
        output_req_sig <= 1'b0;
        block_sync_o   <= 1'b1;
        data_val_o     <= 1'b1;
      end
      else if (output_pos_sig > 0 && output_pos_sig < data_point) begin
        block_sync_o  <= 1'b0;
        data_val_o    <= 1'b1;
      end
    end
  end
  
 //dump for test
 //integer  test_file;
 //always @(posedge clk_sys) begin
 //  if(data_val_o == 1'b1)
 //    $fdisplay(test_file,"%d      %d", data_real_o, data_imag_o);    
 //end   

  //function for bit reverse
  function[10:0] revbin_permute;
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
        4'd3:
            {addr[2], addr[1], addr[0]}
            = {pos[0], pos[1], pos[2]};    
        4'd2:
            {addr[1], addr[0]}
            = {pos[0], pos[1]};                                                                                                     
      endcase
      
      revbin_permute = addr;
    end
  endfunction
endmodule
  
