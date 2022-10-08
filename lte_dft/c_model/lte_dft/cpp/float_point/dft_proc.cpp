//function definitions for dft preprocessing and postprocessing
#include "dft_proc.h"

#define   L    (32)    //upsampling times
#define   P    (6)     //sub filter length

extern double fir_coef[];
extern double comp_factor[9000][2];

void preproc(complex<double> *din, complex<double> *dout, int dft_len, int ldn)
/*
  din:      input data
  dout:     output data
  dft_len:  dft length
  fft_len:  corresponding fft length
*/
{
	int fft_len = (1 << ldn);
	complex<double> delayline[P+1];
	double  c1[P], c2[P], c[P];
	double  acc = P+1+0.5;
	double  ampAcc;
    int     posCoefInt;
    double  posCoefDec;
    complex<double>  temp;
    complex<double>  delta_out;
    double  cnsdelta = (double)dft_len/(double)fft_len;
  
	int input_pos = 0;
	int output_pos = 0;
	
	while(output_pos < fft_len){ 
		//input to delayline
		if(acc >= 1.0) {
		  for(int i = P; i >= 1; i--)
		    delayline[i] = delayline[i-1];
		    			
			if(input_pos < dft_len)
			  delayline[0] = din[input_pos];
			else
				delayline[0] = din[input_pos-dft_len];
		  
		  acc = acc - 1;
          input_pos = input_pos + 1;
		}
		
		//filter operation
		if(acc < 1.0) {
			ampAcc = L*acc;
			posCoefInt = (int)ampAcc;
			posCoefDec = ampAcc - posCoefInt;
			
			//coefficient interpolation
			for(int i = 0; i < P; i++) {
				if(posCoefInt < L-1) {
				  c1[i] = fir_coef[i*L+posCoefInt];
				  c2[i] = fir_coef[i*L+posCoefInt+1];
				  c[i]  = c1[i] + (c2[i]-c1[i])*posCoefDec; 
				}
				else {
					if(i < P-1) {
				    c1[i] = fir_coef[i*L+posCoefInt];
				    c2[i] = fir_coef[i*L+posCoefInt+1];
				    c[i]  = c1[i] + (c2[i]-c1[i])*posCoefDec; 						
					}
					else {
						c1[i] = fir_coef[P*L-1];
						c2[i] = fir_coef[0];
						c[i] = c1[i] + (c2[i]-c1[i])*posCoefDec;
					}
				}
			}
			
			//convolute the new coefs and the data in delayline
			temp = 0;
			for(int k = 0; k < P; k++)
				temp = temp + delayline[k+1]*c[k];
			
			//correction factor
      if(posCoefInt < L-1)
        delta_out = 0;
      else
        delta_out = (delayline[0] - delayline[P])*posCoefDec*fir_coef[0];
    
      temp = temp + delta_out;			
      dout[output_pos] = temp;
      
      acc = acc + cnsdelta;
      output_pos = output_pos + 1;
		}
		
	}
}

void postproc(complex<double> *din, complex<double> *dout, int dft_len, int ldn, bool bit_rev)
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
  
  complex<double> scale_factor;
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
      scale_factor.real = comp_factor[rom_addr][0];
      scale_factor.imag = comp_factor[rom_addr][1];
	}
	else {
      scale_factor.real = comp_factor[rom_addr][0];
      scale_factor.imag = -comp_factor[rom_addr][1];
	}

    
    dout[output_pos] = din[input_index] * scale_factor;
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