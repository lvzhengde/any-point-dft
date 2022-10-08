/*++
Abstract:
    stimulus for testbench
--*/
`include "macros.v"
//`include "fixed_point.v"

module stimuli(
  clk_sys, 
  rst_sys_n, 
  block_sync_o, 
  data_val_o, 
  data_real_o, 
  data_imag_o, 
  ldn_rg_o
  );
  input    clk_sys;
  input    rst_sys_n;
  output reg    block_sync_o;
  output reg    data_val_o;
  output reg signed [`FFT_IN_WIDTH-1:0]    data_real_o;
  output reg signed [`FFT_IN_WIDTH-1:0]    data_imag_o;
`ifndef RAND_TEST
  output [3:0] ldn_rg_o;
`else
  output reg [3:0] ldn_rg_o;
`endif
  
  integer    stimuli_file;
  real       x_r[0:2048], x_i[0:2048];
  
  //always @(rst_sys_n)
  //  if (!rst_sys_n) begin
  //    block_sync_o = 1'b0;
  //    data_val_o = 1'b0;
  //    data_real_o = 0;
  //    data_imag_o = 0;
  //  end

`ifndef RAND_TEST 
  assign ldn_rg_o = `TEST_LDN; 
`endif
    
  task gen_blk_stimuli;
    integer rt_code;
    integer i, j;
    integer fixed_data_real, fixed_data_imag;
    real temp_real, temp_imag;
    integer rand_ldn;
    integer pre_rand_ldn;
    integer fft_len;
    integer len_diff;
    reg [8*200-1:0] filename;
    reg [8*12-1:0]  temp;
    begin
      forever begin
        if (!rst_sys_n) begin
          @(posedge clk_sys) 
          block_sync_o = 1'b0;
          data_val_o = 1'b0;
          data_real_o = 0;
          data_imag_o = 0;
          rand_ldn = 0;
          pre_rand_ldn = 0;
        end
        else begin      
`ifndef   RAND_TEST      
          fft_len = (1 << ldn_rg_o);
`else     
          rand_ldn = ({$random} % 9) + 3;
          fft_len  = (1 << rand_ldn);
          
          len_diff = 0;
          if(pre_rand_ldn != rand_ldn) begin  //to avoid rushing out problems, waiting
            len_diff = (1 << pre_rand_ldn)+38; //plus 28 cylces for processing delay
                    
  `ifdef  FFT_BIT_REV  
            len_diff = (1 << (pre_rand_ldn+1))+38;
  `endif
            @(posedge clk_sys) ;
            block_sync_o = 1'b0;    
            data_val_o = 1'b0;                   
            repeat(len_diff) @(posedge clk_sys) ; 
          end  
          
          ldn_rg_o = rand_ldn; 
          pre_rand_ldn = rand_ldn;  
          
`endif          
          filename = 0;
          case (fft_len)
            8:          temp = "8";
            16:         temp = "16";
            32:         temp = "32";
            64:         temp = "64";
            128:        temp = "128";
            256:        temp = "256";
            512:        temp = "512";
            1024:       temp = "1024";
            2048:       temp = "2048";
            default:    temp = "8";
          endcase           
          filename = {`STIMULI_FILE, temp, ".dat"};
          //$sformat(filename, "%s%d.dat", `STIMULI_FILE, fft_len);
          stimuli_file = $fopen(filename,"r");
          for (i = 0; i < fft_len; i = i+1) begin
            rt_code = $fscanf(stimuli_file, "%f%f", temp_real, temp_imag);            
            if (rt_code > 0) begin
              x_r[i] = temp_real;
              x_i[i] = temp_imag;
            end
          end
          $fclose(stimuli_file);
          
          for (i = 0; i < fft_len; i = i+1) begin 
            @(posedge clk_sys)
            block_sync_o = 1'b0;
            if (i == 0)              
              block_sync_o = 1'b1;   
            data_val_o = 1'b1;       
                                  
            float2fixed_satrnd(x_r[i], `FFT_IN_PTPOS, `FFT_IN_WIDTH, fixed_data_real);        
            float2fixed_satrnd(x_i[i], `FFT_IN_PTPOS, `FFT_IN_WIDTH, fixed_data_imag);
            data_real_o = fixed_data_real;
            data_imag_o = fixed_data_imag;
            
            //each symbol spans several cycles
            @(posedge clk_sys)
            block_sync_o = 1'b0;         
            data_val_o = 1'b0; 
            @(posedge clk_sys) ;              
          end
          
          //@(posedge clk_sys)
          //block_sync_o = 1'b0;         
          //data_val_o = 1'b0;                   
          //for (i = 0; i < `GAP_LEN; i = i+1)
          //  repeat(`INPUT_SYM_CYCLES) @(posedge clk_sys) ;  
        end     
      end         
    end
  endtask

  task float2fixed_satrnd;
    input real x;
    input integer q;
    input integer w;
    output integer y;
    
    real    flt_output;       
    begin   
      flt_output = x * (2.0**q);
      
  	  //symmetrical quantization
  	  if (flt_output >= 0)
  	    flt_output = flt_output + 0.5;
  	  else
  	    flt_output = flt_output - 0.5;
      
  	  //symmetrical saturation
  	  y = $rtoi(flt_output);
  	  
  	  if (y > (1 <<< (w -1)) - 1)
  	    y = (1 <<< (w -1)) - 1;
  	  if (y < -((1 <<< (w -1)) - 1))
  	    y = -((1 <<< (w -1)) - 1);
    end
  endtask

  task fixed2bfp;
    input integer data_real;
    input integer data_imag;
    input integer in_ptpos;
    input integer in_width;
    input integer man_width;
    //input integer exp_width;
    output integer data_real_out;
    output integer data_imag_out;
    output integer data_exp_out;
    
    integer abs_data_real;
    integer abs_data_imag;
    integer abs_max_value;
    integer max_input_value;
    reg [31:0] bits_index;
    integer lshift_count;
    integer exponent;
    integer cutbits;
    integer i;
    reg stop_shift;
    
    begin
      //saturation protection of input data
      max_input_value = (1 <<< (in_width-1))-1;
      data_real_out = data_real;
      data_imag_out = data_imag;
      if (data_real > max_input_value)
        data_real_out = max_input_value;
      if (data_real < -max_input_value)
        data_real_out = -max_input_value;
      if (data_imag > max_input_value)
        data_imag_out = max_input_value;
      if (data_imag < -max_input_value)
        data_imag_out = -max_input_value;
      
      if (data_real_out >= 0)
        abs_data_real = data_real_out;
      else
        abs_data_real = -data_real_out;
      
      if (data_imag_out >= 0)
        abs_data_imag = data_imag_out;
      else
        abs_data_imag = -data_imag_out;
      
      if (abs_data_real >= abs_data_imag)
        abs_max_value = abs_data_real;
      else
        abs_max_value = abs_data_imag;
      
      //emulate barrel shift
      bits_index = abs_max_value;
      lshift_count = 0;
      stop_shift = 0;
      for (i = in_width-2; i >= 0; i = i-1) begin
        if (bits_index[i] == 1) 
          stop_shift = 1;
        if (stop_shift == 0)
          lshift_count = lshift_count + 1;
      end
      
      exponent = in_width - 1 - in_ptpos - lshift_count;
      data_real_out = data_real_out <<< lshift_count;
      data_imag_out = data_imag_out <<< lshift_count;
      
      cutbits = in_width - man_width;
      if (cutbits > 0) begin
        //round real part
        if(data_real_out >= 0) data_real_out = (data_real_out + (1 <<< (cutbits-1))) >>> cutbits;
        else data_real_out = (data_real_out +  (1 <<< (cutbits-1)) -1) >>> cutbits;
        //round imaginary part
        if(data_imag_out >= 0) data_imag_out = (data_imag_out + (1 <<< (cutbits-1))) >>> cutbits;
        else data_imag_out = (data_imag_out +  (1 <<< (cutbits-1)) -1) >>> cutbits; 
      end
      else if (cutbits < 0) begin
        data_real_out = data_real_out << (-cutbits);
        data_imag_out = data_imag_out << (-cutbits);
      end
      
      //saturation
      if (data_real_out > (1 <<< (man_width-1))-1)
        data_real_out = (1 <<< (man_width-1))-1;  
      if (data_real_out < -((1 <<< (man_width-1))-1))
        data_real_out = -((1 <<< (man_width-1))-1);
      if (data_imag_out > (1 <<< (man_width-1))-1)
        data_imag_out = (1 <<< (man_width-1))-1;
      if (data_imag_out < -((1 <<< (man_width-1))-1))
        data_imag_out = -((1 <<< (man_width-1))-1);
                  
      data_exp_out = exponent;
    end
  endtask 
endmodule
  
        
