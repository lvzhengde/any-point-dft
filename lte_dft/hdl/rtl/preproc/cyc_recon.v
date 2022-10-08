/*++
Abstract:
    cyclic reconstruction
--*/

`include "macros.v"
`include "fixed_point.v"

module cyc_recon(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i,
  data_imag_i,
  trans_len_i,
  re_i,
  dout_o, 
	empty_o, 
	almost_empty_o
  );
  parameter DATA_WIDTH = 2*`FFT_IN_WIDTH;
  input    clk_sys;
  input    rst_sys_n;
  input    block_sync_i;
  input    data_val_i;
  input signed [`FFT_IN_WIDTH-1:0] data_real_i;
  input signed [`FFT_IN_WIDTH-1:0] data_imag_i;
  input [10:0]  trans_len_i;
  input    re_i;
  output [DATA_WIDTH-1:0] dout_o;
  output empty_o;
  output almost_empty_o;
  
  //Local signals
  wire  we;
  wire  [DATA_WIDTH-1:0] din;
  wire  full;
  wire  almost_full;  
  reg   [10:0] sample_cnt; 
  wire  [10:0] sample_cnt_p1; 
  reg   cyc_run_out;
  reg   [3:0]  run_out_cnt;
  wire  [3:0]  run_out_cnt_p1;
  
  //cyclic memory
  reg  [DATA_WIDTH-1:0] cyc_mem[`P_LEN:0];
  
  //Instantiate output fifo
  preproc_fifo preproc_fifo(
   .clk_sys         (clk_sys), 
   .rst_sys_n       (rst_sys_n),
   .clr_i           (1'b0),    
   .we_i            (we),     
   .din_i           (din), 
   .re_i            (re_i),     
                    
   .dout_o          (dout_o), 
   .full_o          (full), 
   .empty_o         (empty_o), 
   .almost_full_o   (almost_full),
   .almost_empty_o  (almost_empty_o)
  );  
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
  	if(!rst_sys_n)
  	  sample_cnt <= 0;
    else if(data_val_i == 1'b1)
    	sample_cnt <= sample_cnt_p1;
  end
  
  assign sample_cnt_p1 = (block_sync_i) ? 0 : sample_cnt + 1;
  
  //write data to cyclic memory
  always @(posedge clk_sys) begin
  	if ((data_val_i == 1'b1) && (sample_cnt_p1 <= `P_LEN))
  	  cyc_mem[sample_cnt_p1] <= {data_real_i, data_imag_i};
  end
  
  //write data to FIFO
  always @(posedge clk_sys or negedge rst_sys_n) begin
  	if(!rst_sys_n)
  	  cyc_run_out <= 0;
  	else if(block_sync_i == 1'b1 || run_out_cnt == `P_LEN)
  		cyc_run_out <= 0;
  	else if(sample_cnt_p1 == trans_len_i && run_out_cnt == 0)
  		cyc_run_out <= 1;
  end
  
  always @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
    	run_out_cnt <= 0;
    else if (block_sync_i == 1'b1)
    	run_out_cnt <= 0;
    else if (~almost_full && cyc_run_out)
    	run_out_cnt <= run_out_cnt_p1;
  end
  
  assign run_out_cnt_p1 = run_out_cnt + 1;

  assign cyc_we = (~almost_full && cyc_run_out)? 1'b1 : 1'b0;
     		
  assign we  = (cyc_run_out == 1'b1) ? cyc_we : data_val_i;
  assign din = (cyc_run_out == 1'b1) ? cyc_mem[run_out_cnt] : {data_real_i, data_imag_i}; 
  
endmodule
