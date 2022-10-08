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
  ldn_rg_i
  );

  input clk_sys;
  input rst_sys_n;
  input block_sync_i;
  input data_val_i;
  input signed [`FFT_OUT_WIDTH-1:0] data_real_i;
  input signed [`FFT_OUT_WIDTH-1:0] data_imag_i;
  input [3:0] ldn_rg_i;
  
  integer i, j, k;
  integer fixed_data_real, fixed_data_imag;
  real    db_data_real, db_data_imag;
  real    x_r[0:2048], x_i[0:2048];
  integer dump_file[8:0];
  reg [8*200-1:0] filename;
  reg [8*12-1:0]  temp;  
  reg [10:0] addr;
  integer fft_len;
  integer ldn;
  integer rvd_frms;
  
  initial    //open files
    begin
`ifdef RAND_TEST
      for(j = 0; j < 9; j = j+1) begin
        ldn = j + 3;
        fft_len = (1 << ldn);
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
        filename = {`DUMP_FILE, "_rand", temp, ".dat"};        
        dump_file[j] = $fopen(filename);
      end
`else
      ldn = `TEST_LDN;
      fft_len = (1 << ldn);
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
      filename = 0;
      filename = {`DUMP_FILE,  temp, ".dat"};                           
      dump_file[ldn-3] = $fopen(filename);
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
              fft_len = (1 << ldn); 
              for(k = 0; k < fft_len; k = k+1) begin
                addr = k;
`ifndef FFT_BIT_REV
                addr = revbin_permute(addr, ldn);   
`endif
                $fdisplay(dump_file[ldn-3],"%16.8f   %16.8f", x_r[addr], x_i[addr]);                          
              end             
            end
            
            if(rvd_frms == `DUMP_FRAMES) begin  //close files, stop simulation
`ifdef RAND_TEST
              for(j = 0; j < 9; j = j+1) begin
                $fclose(dump_file[j]);
              end
`else
              ldn = `TEST_LDN;
              $fclose(dump_file[ldn-3]);
`endif       
              $stop;         
            end
            
            ldn = ldn_rg_i;
            rvd_frms = rvd_frms + 1;
            i = 0;
          end  
              
          if (data_val_i == 1'b1) begin
            fixed_data_real = data_real_i;
            fixed_data_imag = data_imag_i;
            fixed2float(fixed_data_real, `FFT_OUT_PTPOS, db_data_real);
            fixed2float(fixed_data_imag, `FFT_OUT_PTPOS, db_data_imag);
            x_r[i] = db_data_real;
            x_i[i] = db_data_imag;
            //$fdisplay(dump_file,"%16.8f %16.8f", db_data_real, db_data_imag); 
            //$fdisplay(dump_file,"%d %d", fixed_data_real, fixed_data_imag);           
            i = i + 1;
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
