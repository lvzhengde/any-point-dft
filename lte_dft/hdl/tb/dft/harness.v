`include "macros.v"
`include "fixed_point.v"

module harness;
  reg     clk_sys;
  reg     rst_sys_n;
  wire    stim_block_sync;
  wire    stim_data_val;
  wire signed [`FFT_IN_WIDTH-1:0] stim_data_real;
  wire signed [`FFT_IN_WIDTH-1:0] stim_data_imag;
  wire [11:0] stim_trans_len;
  wire    stim_inv_en;
  wire duv_block_sync;
  wire duv_data_val;
  wire signed [`FFT_OUT_WIDTH-1:0] duv_data_real;
  wire signed [`FFT_OUT_WIDTH-1:0] duv_data_imag;  
  wire [11:0] duv_trans_len;    
  wire [10:0] duv_data_index;    


  parameter      T_CLK = 10;
  
  dft_wrapper dft_duv(
    .clk_sys         (clk_sys), 
    .rst_sys_n       (rst_sys_n), 
    .block_sync_i    (stim_block_sync), 
    .data_val_i      (stim_data_val), 
    .data_real_i     (stim_data_real),
    .data_imag_i     (stim_data_imag),
    .trans_len_i     (stim_trans_len),
    .inv_en_i        (stim_inv_en),
    .block_sync_o    (duv_block_sync), 
    .data_val_o      (duv_data_val), 
    .data_real_o     (duv_data_real), 
    .data_imag_o     (duv_data_imag),
    .trans_len_o     (duv_trans_len),
    .data_index_o    (duv_data_index)
  );

  stimuli stimuli(
    .clk_sys         (clk_sys), 
    .rst_sys_n       (rst_sys_n), 
    .block_sync_o    (stim_block_sync), 
    .data_val_o      (stim_data_val), 
    .data_real_o     (stim_data_real), 
    .data_imag_o     (stim_data_imag),
    .trans_len_o     (stim_trans_len),
    .inv_en_o        (stim_inv_en)
    );
                   
  monitor monitor(
    .clk_sys         (clk_sys), 
    .rst_sys_n       (rst_sys_n), 
    .block_sync_i    (duv_block_sync), 
    .data_val_i      (duv_data_val), 
    .data_real_i     (duv_data_real), 
    .data_imag_i     (duv_data_imag), 
    .trans_len_i     (duv_trans_len),
    .data_index_i    (duv_data_index)
    );  

  // clock and reset generation
  initial
  begin
      clk_sys = 0;
      rst_sys_n = 1;
  end
  
  // clock generation
  always #(T_CLK/2) clk_sys <= ~clk_sys;
  
  // task for reset operation
  task reset;
  begin
      disable stimuli.gen_blk_stimuli;
      disable monitor.monitor_act;
      
      #55  rst_sys_n = 0;
      #155 rst_sys_n = 1;
  end
  endtask 

endmodule        