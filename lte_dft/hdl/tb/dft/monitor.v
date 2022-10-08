/*++
Abstract:
    monitors for testbench
--*/
`include "macros.v"
`include "fixed_point.v"

module monitor(
  clk_sys, 
  rst_sys_n, 
  block_sync_i, 
  data_val_i, 
  data_real_i, 
  data_imag_i,
  trans_len_i,
  data_index_i
  );

  input clk_sys;
  input rst_sys_n;
  input block_sync_i;
  input data_val_i;
  input signed [`FFT_OUT_WIDTH-1:0] data_real_i;
  input signed [`FFT_OUT_WIDTH-1:0] data_imag_i;
  input [11:0] trans_len_i;
  input [10:0] data_index_i;
  
  integer i, j, k;
  integer fixed_data_real, fixed_data_imag;
  real    db_data_real, db_data_imag;
  real    x_r[0:2048], x_i[0:2048];
  integer dump_file[43:0];
  integer single_dump_file;
  reg [8*200-1:0] filename;
  reg [8*12-1:0]  temp;  
  reg [10:0] addr;
  integer dft_len;
  integer file_index;
  integer rvd_frms;
  
  initial    //open files
    begin
`ifdef RAND_TEST
      for(j = 0; j < 44; j = j+1) begin
        filename = 0;
	      case(j)
	      	//2^n-point FFT
	      	0:     temp = "16"    ;
	      	1:     temp = "32"    ;
	      	2:     temp = "64"    ;
	      	3:     temp = "128"   ;
	      	4:     temp = "256"   ;
	      	5:     temp = "512"   ;
	      	6:     temp = "1024"  ;
	      	7:     temp = "2048"  ;
	        //12*2^a*3^b*5^c-point DFT
	        8:     temp = "12"    ;
	        9:     temp = "24"    ;
	        10:    temp = "36"    ;
          11:    temp = "48"    ;
          12:    temp = "60"    ;
          13:    temp = "72"    ;
          14:    temp = "96"    ;
          15:    temp = "108"   ;
          16:    temp = "120"   ;
          17:    temp = "144"   ;
          18:    temp = "180"   ;
          19:    temp = "192"   ;
          20:    temp = "216"   ;
          21:    temp = "240"   ;
          22:    temp = "288"   ;
          23:    temp = "300"   ;
          24:    temp = "324"   ;
          25:    temp = "360"   ;
          26:    temp = "384"   ;
          27:    temp = "432"   ;
          28:    temp = "480"   ;
          29:    temp = "540"   ;
          30:    temp = "576"   ;
          31:    temp = "600"   ;
          32:    temp = "648"   ;
          33:    temp = "720"   ;
          34:    temp = "768"   ;
          35:    temp = "864"   ;
          36:    temp = "900"   ;
          37:    temp = "960"   ;
          38:    temp = "972"   ;
          39:    temp = "1080"  ;
          40:    temp = "1152"  ;
          41:    temp = "1200"  ;
          42:    temp = "1296"  ;
          43:    temp = "1536" ; 
          default:  temp = "12";
        endcase          
        filename = {`DUMP_FILE, "_rand", temp, ".dat"};        
        dump_file[j] = $fopen(filename);
      end
`else
      dft_len = `TEST_DFT_LEN;
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
        default   : temp = "12";
      endcase          
      filename = 0;
      filename = {`DUMP_FILE,  temp, ".dat"};                           
      single_dump_file = $fopen(filename);
`endif      
    end
  
  task monitor_act;
    begin
      rvd_frms = 0;
      i = 0;
      forever @(posedge clk_sys or negedge rst_sys_n)
      begin
        if (!rst_sys_n) begin
          rvd_frms = 0;
          i = 0;
        end
        else begin
          if (block_sync_i == 1'b1) begin
            if(rvd_frms > 0) begin    //dump data to files 
              for(k = 0; k < dft_len; k = k+1) begin
                addr = k;
`ifdef RAND_TEST
                file_index = len_index(dft_len);
                $fdisplay(dump_file[file_index],"%16.8f   %16.8f", x_r[addr], x_i[addr]);  
`else
                $fdisplay(single_dump_file,"%16.8f   %16.8f", x_r[addr], x_i[addr]);  
`endif                        
              end             
            end
            
            if(rvd_frms == `DUMP_FRAMES) begin  //close files, stop simulation
`ifdef RAND_TEST
              for(j = 0; j < 44; j = j+1) begin
                $fclose(dump_file[j]);
              end
`else
              $fclose(single_dump_file);
`endif       
              $stop;         
            end
            
            dft_len = $unsigned(trans_len_i);
            rvd_frms = rvd_frms + 1;
            i = 0;
          end  
              
          if (data_val_i == 1'b1) begin
            fixed_data_real = data_real_i;
            fixed_data_imag = data_imag_i;
            fixed2float(fixed_data_real, `FFT_OUT_PTPOS, db_data_real);
            fixed2float(fixed_data_imag, `FFT_OUT_PTPOS, db_data_imag);
            i = $unsigned(data_index_i);
            x_r[i] = db_data_real;
            x_i[i] = db_data_imag;
            //$fdisplay(dump_file,"%16.8f %16.8f", db_data_real, db_data_imag); 
            //$fdisplay(dump_file,"%d %d", fixed_data_real, fixed_data_imag);           
            //i = i + 1;
          end   
                
        end         
      end
    end
  endtask
  
  //semifloat to fixed-point conversion
  task bfp2fixed;
    input integer data_real_in;
    input integer data_imag_in;
    input integer data_exp_in;
    input integer man_width;
    input integer out_ptpos;
    input integer out_width;
    output integer data_real_out;
    output integer data_imag_out;
    
    integer shift_count, cutbits;
    begin
      shift_count = out_ptpos + data_exp_in - (man_width - 1);
      data_real_out = data_real_in;
      data_imag_out = data_imag_in;
      if (shift_count >=0) begin   //left shift
        data_real_out = data_real_out <<< shift_count;
        data_imag_out = data_imag_out <<< shift_count;
      
        //symmetrical saturation
        if (data_real_out > (1 <<< (out_width-1))-1)
          data_real_out = (1 <<< (out_width-1))-1;
        if (data_real_out < -((1 <<< (out_width-1))-1))
          data_real_out = -((1 <<< (out_width-1))-1);
        if (data_imag_out > (1 <<< (out_width-1))-1)
          data_imag_out = (1 <<< (out_width-1))-1;
        if (data_imag_out < -((1 <<< (out_width-1))-1))
          data_imag_out = -((1 <<< (out_width-1))-1);  
      end
      else begin   //right shift with round
        cutbits = -shift_count;
      	if (data_real_out >= 0)
      	  data_real_out = (data_real_out + (1 <<< (cutbits-1)))>>> cutbits;
      	else
          data_real_out = (data_real_out+(1<<<(cutbits-1))-1)>>>cutbits;  	
      	if (data_imag_out >= 0)
      	  data_imag_out = (data_imag_out + (1 <<< (cutbits-1)))>>> cutbits;
      	else
          data_imag_out = (data_imag_out+(1<<<(cutbits-1))-1)>>>cutbits;  	  
      end
    end 
  endtask
  
  //fixed point to float point conversion
  task fixed2float;
    input integer x;
    input integer q;
    output real y;
    
    real divisor;
    begin    
      divisor = $itor(1<<<q);
      y = $itor(x) / divisor;
    end
  endtask

  //function for bit reverse
  function[5:0] len_index;
  input [11:0] trans_len;
    begin
	    case(trans_len)
	    	//2^n-point FFT
	    	16   :   len_index = 0 ;
	    	32   :   len_index = 1 ;
	    	64   :   len_index = 2 ;
	    	128  :   len_index = 3 ;
	    	256  :   len_index = 4 ;
	    	512  :   len_index = 5 ;
	    	1024 :   len_index = 6 ;
	    	2048 :   len_index = 7 ;
	      //12*2^a*13^b*5^c-point DFT
	      12   :   len_index = 8  ;  
	      24   :   len_index = 9  ;  
	      36   :   len_index = 10 ; 
        48   :   len_index = 11 ; 
        60   :   len_index = 12 ; 
        72   :   len_index = 13 ; 
        96   :   len_index = 14 ; 
        108  :   len_index = 15 ; 
        120  :   len_index = 16 ; 
        144  :   len_index = 17 ; 
        180  :   len_index = 18 ; 
        192  :   len_index = 19 ; 
        216  :   len_index = 20 ; 
        240  :   len_index = 21 ; 
        288  :   len_index = 22 ; 
        300  :   len_index = 23 ; 
        324  :   len_index = 24 ; 
        360  :   len_index = 25 ; 
        384  :   len_index = 26 ; 
        432  :   len_index = 27 ; 
        480  :   len_index = 28 ; 
        540  :   len_index = 29 ; 
        576  :   len_index = 30 ; 
        600  :   len_index = 31 ; 
        648  :   len_index = 32 ; 
        720  :   len_index = 33 ; 
        768  :   len_index = 34 ; 
        864  :   len_index = 35 ; 
        900  :   len_index = 36 ; 
        960  :   len_index = 37 ; 
        972  :   len_index = 38 ; 
        1080 :   len_index = 39 ; 
        1152 :   len_index = 40 ; 
        1200 :   len_index = 41 ; 
        1296 :   len_index = 42 ; 
        1536 :   len_index = 43 ; 
        default: len_index = 8; 
      endcase          
    end
  endfunction
  
endmodule
