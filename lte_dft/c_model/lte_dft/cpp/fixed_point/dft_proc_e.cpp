//function definitions for dft preprocessing and postprocessing
#include "stdio.h"
#include "fft_fixed_point.h"
#include "dft_proc_e.h"
#include "macros.h"

extern double fir_coef[];
extern double comp_factor[9000][2];

void preproc_e(int *din_re, int *din_im, int *dout_re, int *dout_im, int dft_len, int ldn)
/*
  din:      input data
  dout:     output data
  dft_len:  dft length
  fft_len:  corresponding fft length
*/
{
	int  fft_len = (1 << ldn);
	int  delayline_re[P+1];  
	int  delayline_im[P+1];
	int  c1[P], c2[P], c[P];     //1.13, coefficient width 14
	int  acc = (1 << 10);        //acc = P+1+0.5, 2.11
	int  ampAcc;
  int  posCoefInt;
  int  posCoefDec;
  int  temp_re, temp_im;
  int  delta_out_re, delta_out_im;
  int  cnsdelta = (int)(((double)dft_len/(double)fft_len) * (1 << 11)); //x.11
  int  fir_coef_e[L*P];
  int  i;
  
  FILE  *fir_coef_file;
  fir_coef_file = fopen(FIR_COEF_FILE, "wt+");
  //convert float-point fir coefficients to fixed-point
  for(i = 0; i < L*P; i++) {
  	fir_coef_e[i] = float2fixed_satrnd(fir_coef[i], FIR_CO_WIDTH-1, FIR_CO_WIDTH);
  	fprintf(fir_coef_file,"%d\n",fir_coef_e[i]);
  }
  fclose(fir_coef_file);
  
	int input_pos = 0;
	int output_pos = 0;
	
  //stuff first P+1 elements of delayline
  for(i = 0; i < P+1; i++) {
  	 for(int j = P; j >= 1; j--) {
		    delayline_re[j] = delayline_re[j-1];
		    delayline_im[j] = delayline_im[j-1];		    
		 }
		    			
			delayline_re[0] = din_re[input_pos];
			delayline_im[0] = din_im[input_pos];			
			
      input_pos = input_pos + 1;
  }	
	
	int cutbits;
	int temp_c;
	while(output_pos < fft_len){ 
		//input to delayline
		if(acc >= (1 << 11)) {     //in fixed-point form 1 corresponding to 1<<11
		  for(i = P; i >= 1; i--) {
		    delayline_re[i] = delayline_re[i-1];
		    delayline_im[i] = delayline_im[i-1];		    
		  }
		    			
			if(input_pos < dft_len) {
			  delayline_re[0] = din_re[input_pos];
			  delayline_im[0] = din_im[input_pos];			  
			}
			else {
				delayline_re[0] = din_re[input_pos-dft_len];
				delayline_im[0] = din_im[input_pos-dft_len];				
			}
		  
		  acc = acc - (1 << 11);
      input_pos = input_pos + 1;
		}
		
		//filter operation
		if(acc < (1 << 11)) {
			ampAcc = L*acc;
			posCoefInt = (ampAcc >> 11);
			posCoefDec = ampAcc - (posCoefInt << 11);
			
			//coefficient interpolation
			cutbits = 11;
			for(i = 0; i < P; i++) {
				if(posCoefInt < L-1) {
				  c1[i] = fir_coef_e[i*L+posCoefInt];
				  c2[i] = fir_coef_e[i*L+posCoefInt+1];
				}
				else {
					if(i < P-1) {
				    c1[i] = fir_coef_e[i*L+posCoefInt];
				    c2[i] = fir_coef_e[i*L+posCoefInt+1];		
					}
					else {
						c1[i] = fir_coef_e[P*L-1];
						c2[i] = fir_coef_e[0];
					}
				}
				
				temp_c = (c1[i]<<11) + (c2[i]-c1[i])*posCoefDec;
				c[i]  = SymRoundShift(temp_c, cutbits);			
			}
			
			//convolute the new coefs and the data in delayline
			int x_r_mul, x_i_mul;
			int x_r_sum, x_i_sum;
			temp_re = 0;
			temp_im = 0;
			for(int k = 0; k < P; k++) {
				cutbits = FIR_CO_WIDTH-1;
				x_r_mul = delayline_re[k+1]*c[k];
				x_i_mul = delayline_im[k+1]*c[k];
				x_r_sum = SymRoundShift(x_r_mul, cutbits);
				x_i_sum = SymRoundShift(x_i_mul, cutbits);
				temp_re = temp_re + x_r_sum;
				temp_im = temp_im + x_i_sum;
			}
			
		  //correction factor
      //correction factor (x(n+1)-x(n-P+1))*posCoefDec*c0(0)
      //c0(0)=-0.00052229, special case fixed point 1.13		  
			int x_r_diff, x_i_diff;
			int delta0_r, delta0_i;
			int delta1_r, delta1_i;
			int delta2_r, delta2_i;
      if(posCoefInt < L-1) {
        delta_out_re = 0;
        delta_out_im = 0;
      }
      else {
        x_r_diff = delayline_re[P] - delayline_re[0];
        x_i_diff = delayline_im[P] - delayline_im[0];
        
        delta0_r = x_r_diff * posCoefDec;
        delta0_i = x_i_diff * posCoefDec;  
        delta1_r = SymRoundShift(delta0_r, 11);     
        delta1_i = SymRoundShift(delta0_i, 11);  
        
        delta2_r = (delta1_r << 2);
        delta2_i = (delta1_i << 2);  
        delta2_r = SymRoundShift(delta2_r, (FIR_CO_WIDTH-1));     
        delta2_i = SymRoundShift(delta2_i, (FIR_CO_WIDTH-1));        	
      	
        //delta_out = (delayline[0] - delayline[P])*posCoefDec*fir_coef[0];
        delta_out_re = delta2_r;
        delta_out_im = delta2_i;
      }
    
      temp_re = temp_re + delta_out_re;
      temp_im = temp_im + delta_out_im;      			
      dout_re[output_pos] = temp_re;
      dout_im[output_pos] = temp_im;      
      
      acc = acc + cnsdelta;
      output_pos = output_pos + 1;
		}
		
	}
}

void postproc_e(int *din_re, int *din_im, int *dout_re, int *dout_im, int dft_len, int ldn, bool bit_rev)
/*
  din:      input data, after fft
  dout:     output data, dft result
  dft_len:  dft length
  fft_len:  corresponding fft length
  bit_rev:  true-fft result in bit reverse order, false-in nature order
*/
{
	int fft_len = (1 << ldn);
	int addr_base;
	int addr_offset;
	int rom_addr;
	int N_div_2 = (dft_len >> 1);
	int mid_point = N_div_2 + fft_len - dft_len;
	int input_pos;
	int output_pos;
	int input_index;
	int comp_factor_e[9000][2];
	
	//convert float-point compensation factors to fixed-point
	int   single_factor;
	FILE  *comp_file;
  comp_file = fopen(COMP_FILE, "wt+");
  for(int i = 0; i < 9000; i++) {
  	comp_factor_e[i][0] = float2fixed_satrnd(comp_factor[i][0], 10, 13);   //S3.10
  	comp_factor_e[i][1] = float2fixed_satrnd(comp_factor[i][1], 10, 13);   //S3.10 
  	single_factor = (comp_factor_e[i][1] << 13) + (comp_factor_e[i][0] & 0x1fff);
  	fprintf(comp_file,"%d\n",single_factor); 	
  } 
  fclose(comp_file);
	
	switch(dft_len) {
	  case 12    :   addr_base = 0    ; break;
	  case 24    :   addr_base = 7    ; break;
	  case 36    :   addr_base = 20   ; break;
    case 48    :   addr_base = 39   ; break;
    case 60    :   addr_base = 64   ; break;
    case 72    :   addr_base = 95   ; break;
    case 96    :   addr_base = 132  ; break;
    case 108   :   addr_base = 181  ; break;
    case 120   :   addr_base = 236  ; break;
    case 144   :   addr_base = 297  ; break;
    case 180   :   addr_base = 370  ; break;
    case 192   :   addr_base = 461  ; break;
    case 216   :   addr_base = 558  ; break;
    case 240   :   addr_base = 667  ; break;
    case 288   :   addr_base = 788  ; break;
    case 300   :   addr_base = 933  ; break;
    case 324   :   addr_base = 1084 ; break;
    case 360   :   addr_base = 1247 ; break;
    case 384   :   addr_base = 1428 ; break;
    case 432   :   addr_base = 1621 ; break;
    case 480   :   addr_base = 1838 ; break;
    case 540   :   addr_base = 2079 ; break;
    case 576   :   addr_base = 2350 ; break;
    case 600   :   addr_base = 2639 ; break;
    case 648   :   addr_base = 2940 ; break;
    case 720   :   addr_base = 3265 ; break;
    case 768   :   addr_base = 3626 ; break;
    case 864   :   addr_base = 4011 ; break;
    case 900   :   addr_base = 4444 ; break;
    case 960   :   addr_base = 4895 ; break;
    case 972   :   addr_base = 5376 ; break;
    case 1080  :   addr_base = 5863 ; break;
    case 1152  :   addr_base = 6404 ; break;
    case 1200  :   addr_base = 6981 ; break;
    case 1296  :   addr_base = 7582 ; break;
    case 1536  :   addr_base = 8231 ; break;
    default    :   addr_base = 0;	
  }
  
  int scale_factor_re;
  int scale_factor_im;
  for(input_pos = 0; input_pos < fft_len; input_pos++) {
  	//get compesation factor
  	if(bit_rev == false)
  		input_index = bit_reverse(input_pos, ldn);
  	else
  		input_index = input_pos;
  		
    if(input_index <= N_div_2)
    	output_pos = input_index;
    else if(input_index > mid_point)
    	output_pos = input_index + dft_len - fft_len;
    else  //jump to next position
    	continue;
    
    addr_offset = (output_pos <= N_div_2) ? output_pos : (dft_len - output_pos);
    rom_addr = addr_base + addr_offset;
	  if(output_pos <= N_div_2) {
        scale_factor_re = comp_factor_e[rom_addr][0];
        scale_factor_im = comp_factor_e[rom_addr][1];
	  }
	  else {
        scale_factor_re =  comp_factor_e[rom_addr][0];
        scale_factor_im = -comp_factor_e[rom_addr][1];
	  }

    
    //dout[output_pos] = din[input_index] * scale_factor;
    int temp1, temp2, temp3; 
	  temp1 = (din_re[input_index] + din_im[input_index]) * scale_factor_re; 
	  temp2 = din_im[input_index] * (scale_factor_im + scale_factor_re);
	  temp3 = din_re[input_index] * (scale_factor_im - scale_factor_re);	  
	  
    temp1 = SymRoundShift(temp1, 10);
    temp2 = SymRoundShift(temp2, 10);
    temp3 = SymRoundShift(temp3, 10);
    
    //should make sure no overflow occurs
	  dout_re[output_pos] = temp1 - temp2;
	  dout_im[output_pos] = temp1 + temp3;	       	  
  }
}


int  bit_reverse(int x, int ldn)
/*
  x:      input index
  ldn:    log2(fft_len)
  return: output bit-reversed index
*/
{
  int reverse_index = 0;
  
  for(int j = 0; j < ldn; j++)
  {
    reverse_index = reverse_index << 1; 
    reverse_index = reverse_index + (x&0x1); //parentheses is needed to clarify
    x = x >> 1;   
  }  
  
  return reverse_index;        	
}