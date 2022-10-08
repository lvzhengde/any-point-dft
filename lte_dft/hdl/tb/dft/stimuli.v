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
  trans_len_o,
  inv_en_o
  );
  input    clk_sys;
  input    rst_sys_n;
  output reg    block_sync_o;
  output reg    data_val_o;
  output reg signed [`FFT_IN_WIDTH-1:0]    data_real_o;
  output reg signed [`FFT_IN_WIDTH-1:0]    data_imag_o;
`ifndef RAND_TEST
  output [11:0] trans_len_o;
`else
  output reg [11:0] trans_len_o;
`endif
  output inv_en_o;
  
  integer    stimuli_file;
  real       x_r[0:2048], x_i[0:2048];
  reg  [1:0] t1, t2;
  reg        t_sel;
  
  always @(rst_sys_n)
    if (!rst_sys_n) begin
      block_sync_o = 1'b0;
      data_val_o = 1'b0;
      data_real_o = 0;
      data_imag_o = 0;
`ifdef RAND_TEST       
      trans_len_o = 0;
`endif
      t_sel = 0;
      t1 = 3;
      t2 = 3;
    end

`ifndef RAND_TEST 
  assign trans_len_o = `TEST_DFT_LEN; 
`endif
  assign inv_en_o = `DFT_MODE;
    
  task gen_blk_stimuli;
    integer rt_code;
    integer i, j;
    integer fixed_data_real, fixed_data_imag;
    real temp_real, temp_imag;
    integer pre_dft_len;
    integer dft_len;
    integer len_diff;
    integer len_index;
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
`ifdef RAND_TEST          
          trans_len_o = 0;
`endif
          t_sel = 0;       
          t1 = 3;          
          t2 = 3;          

          dft_len = 0;
          pre_dft_len = 0;
          len_diff = 0;
        end
        else begin      
`ifndef   RAND_TEST      
          dft_len = trans_len_o;
`else     
          len_index = {$random} % 44;
          
	        case(len_index)
	        	//2^n-point FFT
	        	0:   dft_len = 16    ; 
	        	1:   dft_len = 32    ; 
	        	2:   dft_len = 64    ; 
	        	3:   dft_len = 128   ; 
	        	4:   dft_len = 256   ; 
	        	5:   dft_len = 512   ; 
	        	6:   dft_len = 1024  ; 
	        	7:   dft_len = 2048  ; 
	        	//12*2^a*3^b*5^c-point DFT
	          8:   dft_len = 12    ;    
	          9:   dft_len = 24    ;    
	          10:  dft_len = 36    ;    
            11:  dft_len = 48    ;    
            12:  dft_len = 60    ;    
            13:  dft_len = 72    ;    
            14:  dft_len = 96    ;    
            15:  dft_len = 108   ;    
            16:  dft_len = 120   ;    
            17:  dft_len = 144   ;    
            18:  dft_len = 180   ;    
            19:  dft_len = 192   ;    
            20:  dft_len = 216   ;    
            21:  dft_len = 240   ;    
            22:  dft_len = 288   ;    
            23:  dft_len = 300   ;    
            24:  dft_len = 324   ;    
            25:  dft_len = 360   ;    
            26:  dft_len = 384   ;    
            27:  dft_len = 432   ;    
            28:  dft_len = 480   ;    
            29:  dft_len = 540   ;    
            30:  dft_len = 576   ;    
            31:  dft_len = 600   ;    
            32:  dft_len = 648   ;    
            33:  dft_len = 720   ;    
            34:  dft_len = 768   ;    
            35:  dft_len = 864   ;    
            36:  dft_len = 900   ;    
            37:  dft_len = 960   ;    
            38:  dft_len = 972   ;    
            39:  dft_len = 1080  ;    
            40:  dft_len = 1152  ;    
            41:  dft_len = 1200  ;    
            42:  dft_len = 1296  ;    
            43:  dft_len = 1536  ;    
            default   : dft_len = 12; 
          endcase          

          len_diff = 0;
          if(pre_dft_len != dft_len) begin  //to avoid rushing out problems, waiting
            len_diff = pre_dft_len+38+25; //plus 28 cylces for processing delay
                    
            @(posedge clk_sys) ;
            block_sync_o = 1'b0;    
            data_val_o = 1'b0;                   
            repeat(len_diff) @(posedge clk_sys) ; 
          end  
          
          trans_len_o = dft_len; 
          pre_dft_len = dft_len;  
          
`endif 
          filename = 0;   
                
	        case(dft_len)
	        	//2^n-point FFT
	        	16   :     temp = "16"    ; 
	        	32   :     temp = "32"    ; 
	        	64   :     temp = "64"    ; 
	        	128  :     temp = "128"   ; 
	        	256  :     temp = "256"   ; 
	        	512  :     temp = "512"   ; 
	        	1024 :     temp = "1024"  ; 
	        	2048 :     temp = "2048"  ; 
	        	//12*2^a*3^b*5^c-point DFT
	          12   :     temp = "12"    ;
	          24   :     temp = "24"    ;
	          36   :     temp = "36"    ;
            48   :     temp = "48"    ;
            60   :     temp = "60"    ;
            72   :     temp = "72"    ;
            96   :     temp = "96"    ;
            108  :     temp = "108"   ;
            120  :     temp = "120"   ;
            144  :     temp = "144"   ;
            180  :     temp = "180"   ;
            192  :     temp = "192"   ;
            216  :     temp = "216"   ;
            240  :     temp = "240"   ;
            288  :     temp = "288"   ;
            300  :     temp = "300"   ;
            324  :     temp = "324"   ;
            360  :     temp = "360"   ;
            384  :     temp = "384"   ;
            432  :     temp = "432"   ;
            480  :     temp = "480"   ;
            540  :     temp = "540"   ;
            576  :     temp = "576"   ;
            600  :     temp = "600"   ;
            648  :     temp = "648"   ;
            720  :     temp = "720"   ;
            768  :     temp = "768"   ;
            864  :     temp = "864"   ;
            900  :     temp = "900"   ;
            960  :     temp = "960"   ;
            972  :     temp = "972"   ;
            1080 :     temp = "1080"  ;
            1152 :     temp = "1152"  ;
            1200 :     temp = "1200"  ;
            1296 :     temp = "1296"  ;
            1536 :     temp = "1536"  ;
            default   : temp = "12"   ;
          endcase          
          
          filename = {`STIMULI_FILE, temp, ".dat"};
          stimuli_file = $fopen(filename,"r");
          for (i = 0; i < dft_len; i = i+1) begin
            rt_code = $fscanf(stimuli_file, "%f%f", temp_real, temp_imag);            
            if (rt_code > 0) begin
              x_r[i] = temp_real;
              x_i[i] = temp_imag;
            end
          end
          $fclose(stimuli_file);  
          
          sym_period(dft_len, t1, t2);
          
          for (i = 0; i < dft_len; i = i+1) begin 
            @(posedge clk_sys)
            block_sync_o = 1'b0;
            if (i == 0)              
              block_sync_o = 1'b1;   
            data_val_o = 1'b1;       
                                  
            float2fixed_satrnd(x_r[i], `FFT_IN_PTPOS, `FFT_IN_WIDTH, fixed_data_real);        
            float2fixed_satrnd(x_i[i], `FFT_IN_PTPOS, `FFT_IN_WIDTH, fixed_data_imag);
            data_real_o = fixed_data_real;
            data_imag_o = fixed_data_imag;
            
            //adjust symbol rate to adapt to throughput       
            if(t_sel == 1'b0)  begin //symbol peroid I
              case(t1)
                2'd1:   ;            //do nothing
                2'd2:   begin
                  @(posedge clk_sys)
                  block_sync_o = 1'b0;         
                  data_val_o = 1'b0; 
                end
                2'd3:   begin
                  @(posedge clk_sys)
                  block_sync_o = 1'b0;         
                  data_val_o = 1'b0; 
                  @(posedge clk_sys);
                end 
                default: ;
              endcase               
            end
            else  begin              //symbol peroid II
              case(t2)
                2'd1:   ;            //do nothing
                2'd2:   begin
                  @(posedge clk_sys)
                  block_sync_o = 1'b0;         
                  data_val_o = 1'b0; 
                end
                2'd3:   begin
                  @(posedge clk_sys)
                  block_sync_o = 1'b0;         
                  data_val_o = 1'b0; 
                  @(posedge clk_sys);
                end 
                default: ;
              endcase                             
            end     

            t_sel = ~t_sel;
            
            //additional idle cycles added
            //@(posedge clk_sys)
            //block_sync_o = 1'b0;         
            //data_val_o = 1'b0; 
            //@(posedge clk_sys) ;              
          end
          
          if(!((t1 == 1 && t2 == 1) && (dft_len != 12))) begin
            @(posedge clk_sys)
            block_sync_o = 1'b0;         
            data_val_o = 1'b0;                   
            for (i = 0; i < `P_LEN+2; i = i+1)
              repeat(`INPUT_SYM_CYCLES) @(posedge clk_sys) ;
          end  
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
  
 task sym_period;
    input [10:0] trans_size;
    output [1:0] T1, T2;
     
    begin   
	    case(trans_size)
	    	//2^n-point FFT
	    	16   :      begin  T1 =  1;  T2 =  1;  end   
	    	32   :      begin  T1 =  1;  T2 =  1;  end   
	    	64   :      begin  T1 =  1;  T2 =  1;  end
	    	128  :      begin  T1 =  1;  T2 =  1;  end
	    	256  :      begin  T1 =  1;  T2 =  1;  end
	    	512  :      begin  T1 =  1;  T2 =  1;  end
	    	1024 :      begin  T1 =  1;  T2 =  1;  end
	    	2048 :      begin  T1 =  1;  T2 =  1;  end
	    	//12*2^a*3^b*5^c-point DFT
	      12   :      begin  T1 =  1;  T2 =  1;  end   // 1.33
	      24   :      begin  T1 =  1;  T2 =  2;  end   // 1.33
	      36   :      begin  T1 =  2;  T2 =  2;  end   // 1.78
        48   :      begin  T1 =  1;  T2 =  2;  end   // 1.33
        60   :      begin  T1 =  2;  T2 =  3;  end   // 2.13
        72   :      begin  T1 =  2;  T2 =  2;  end   // 1.78
        96   :      begin  T1 =  1;  T2 =  2;  end   // 1.33
        108  :      begin  T1 =  2;  T2 =  3;  end   // 2.37
        120  :      begin  T1 =  2;  T2 =  3;  end   // 2.13
        144  :      begin  T1 =  2;  T2 =  2;  end   // 1.78
        180  :      begin  T1 =  1;  T2 =  2;  end   // 1.42
        192  :      begin  T1 =  1;  T2 =  2;  end   // 1.33
        216  :      begin  T1 =  2;  T2 =  3;  end   // 2.37
        240  :      begin  T1 =  2;  T2 =  3;  end   // 2.13
        288  :      begin  T1 =  2;  T2 =  2;  end   // 1.78
        300  :      begin  T1 =  2;  T2 =  2;  end   // 1.71
        324  :      begin  T1 =  2;  T2 =  2;  end   // 1.58
        360  :      begin  T1 =  1;  T2 =  2;  end   // 1.42
        384  :      begin  T1 =  1;  T2 =  2;  end   // 1.33
        432  :      begin  T1 =  2;  T2 =  3;  end   // 2.37
        480  :      begin  T1 =  2;  T2 =  3;  end   // 2.13
        540  :      begin  T1 =  2;  T2 =  2;  end   // 1.89
        576  :      begin  T1 =  2;  T2 =  2;  end   // 1.78
        600  :      begin  T1 =  2;  T2 =  2;  end   // 1.71
        648  :      begin  T1 =  2;  T2 =  2;  end   // 1.58
        720  :      begin  T1 =  1;  T2 =  2;  end   // 1.42
        768  :      begin  T1 =  1;  T2 =  2;  end   // 1.33
        864  :      begin  T1 =  2;  T2 =  3;  end   // 2.37
        900  :      begin  T1 =  2;  T2 =  3;  end   // 2.28
        960  :      begin  T1 =  2;  T2 =  3;  end   // 2.13
        972  :      begin  T1 =  2;  T2 =  3;  end   // 2.11
        1080 :      begin  T1 =  2;  T2 =  2;  end   // 1.90
        1152 :      begin  T1 =  2;  T2 =  2;  end   // 1.78
        1200 :      begin  T1 =  2;  T2 =  2;  end   // 1.71
        1296 :      begin  T1 =  2;  T2 =  2;  end   // 1.58
        1536 :      begin  T1 =  1;  T2 =  2;  end   // 1.33
        default   : begin  T1 =  1;  T2 =  1;  end
      endcase          
    end
  endtask
    
endmodule
  
        
