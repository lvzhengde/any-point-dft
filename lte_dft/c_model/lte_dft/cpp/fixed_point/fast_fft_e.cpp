#include "fft_fixed_point.h"
#include "fast_fft_e.h"
#include "macros.h"
#include "stdio.h"

#define  MAX_ADDR_BITS    (12)

FILE  *test_file;

static const unsigned long RX = 4;
static const unsigned long LX = 2;

void fast_fft_e(int *data_real, int *data_imag, int *data_exp, unsigned long ldn, int is, bool bit_rev)

//decimation in frequency radix-2^2 FFT main body
//pipelined implementation
//semi-float version
{
    int *d_real;
    int *d_imag;
    int *d_exp;
    int data_ldn;
    const unsigned long N_FFT = (1UL<<ldn);
    
    //test_file = fopen(TEST_FILE, "wt+");

    //decompose computation of FFT into pipeline stages
    for (unsigned long ldm=ldn; ldm>=LX; ldm-=LX)
    {
      int m = (1UL<<ldm);
      int i = 0;
      for (unsigned long j = 0; j < (1UL << ldn); j=j+(1UL << ldm))
      {
        int init_addr = i << ldm;
        d_real = &data_real[init_addr];
        d_imag = &data_imag[init_addr];
        d_exp = &data_exp[init_addr];
        
        data_ldn = ldm;
        radix4_stage_e(d_real, d_imag, d_exp, data_ldn, is);
        i = i + 1;
      }
    }

    //for test
	  //int k;
	  //test_file = fopen(TEST_FILE, "wt+");
	  //for(k = 0; k < (1<<ldn); k++) {
	  //	fprintf(test_file, "%d      %d     %d\n", data_real[k], data_imag[k], data_exp[k]);
	  //}
	  //fclose(test_file);
    
    if ( (ldn&1)!=0 )  // n is not a power of 4, need additional radix-2 step
    {
        for (unsigned long r=0; r<N_FFT; r+=2)
        {
          int u_real = data_real[r];
          int u_imag = data_imag[r];
          int u_exp = data_exp[r];  
          int v_real = data_real[r+1];
          int v_imag = data_imag[r+1];
          int v_exp = data_exp[r+1];  

           //input scaling                                                                             
           int common_exp_in = input_scaling(u_real, u_imag, u_exp, v_real, v_imag, v_exp, MAN_WIDTH); 
                                                                                                       
           //butterfly algorithm                                                                       
           //bit width increase 1                                                                      
           int u_real_out = u_real + v_real;                                                           
           int u_imag_out = u_imag + v_imag;                                                           
           int v_real_out = u_real - v_real;                                                           
           int v_imag_out = u_imag - v_imag;                                                           
                                                                                             
           //ouput scaling and rounding                                            
           int u_exp_out = output_scaling(u_real_out, u_imag_out, common_exp_in);  
           int v_exp_out = output_scaling(v_real_out, v_imag_out, common_exp_in);  
                                                                        
           //output results               
           data_real[r] = u_real_out;    
           data_imag[r] = u_imag_out;    
           data_exp[r] = u_exp_out;      
           data_real[r+1] = v_real_out;    
           data_imag[r+1] = v_imag_out;    
           data_exp[r+1] = v_exp_out;      
        }
    }

    // bit reverse for output address
	if(bit_rev == true)
      revbin_permute_e(data_real, data_imag, data_exp, ldn);

    //if(ldn == 7) {
    //  for(int i = 0; i < N_FFT; i++) {
    //    bfp2fixed(data_real[i], data_imag[i], data_exp[i], MAN_WIDTH, OUT_PTPOS, OUT_WIDTH);
    //    fprintf(test_file, "%d      %d\n", data_real[i], data_imag[i]); 
    //  }
    //}    

    
    //fclose(test_file);
}

void radix4_stage_e(int *data_real, int *data_imag, int *data_exp, unsigned long data_ldn, int is)
{
    double m_pi = 4*atan(1.0);
    double s2pi = ( is>0 ? 2.0*m_pi : -2.0*m_pi );  
    const unsigned long N = (1UL << data_ldn);
    const unsigned long N_DIV_4 = N >> 2;
    const unsigned long N_DIV_2 = N >> 1;
    
    double ph0 = s2pi / N;
    
    int u_real_in, u_imag_in, u_exp_in;
    int v_real_in, v_imag_in, v_exp_in;
    int u_real_out, u_imag_out, u_exp_out;
    int v_real_out, v_imag_out, v_exp_out;
    
    //calculate the first stage radix-2 butterfly
    unsigned long i;
    unsigned long k1;
    unsigned long k2;
    unsigned long n3;
    
    //dump for test
    //if(data_ldn == 11) {
    //  for(i = 0; i < N; i++) {
    //    fprintf(test_file, "%d      %d      %d\n", data_real[i], data_imag[i], data_exp[i]); 
    //  }
    //}        
    //    
    for (i = 0; i < N_DIV_2; i++)
    {
      u_real_in = data_real[i];
      u_imag_in = data_imag[i];
      u_exp_in = data_exp[i];
      v_real_in = data_real[i+N_DIV_2];
      v_imag_in = data_imag[i+N_DIV_2];
      v_exp_in = data_exp[i+N_DIV_2];   
         
      //input scaling                                                                            
      int common_exp_in = input_scaling(u_real_in, u_imag_in, u_exp_in, v_real_in, v_imag_in, v_exp_in, MAN_WIDTH);
           
      //butterfly algorithm                                                                       
      //bit width increase 1                                                                      
      u_real_out = u_real_in + v_real_in;                                                           
      u_imag_out = u_imag_in + v_imag_in;                                                           
      v_real_out = u_real_in - v_real_in;                                                           
      v_imag_out = u_imag_in - v_imag_in;   

      //ouput scaling and rounding                                            
      u_exp_out = output_scaling(u_real_out, u_imag_out, common_exp_in);  
      v_exp_out = output_scaling(v_real_out, v_imag_out, common_exp_in);  
                                                                   
      //output results               
      data_real[i] = u_real_out;    
      data_imag[i] = u_imag_out;    
      data_exp[i] = u_exp_out;      
      data_real[i+N_DIV_2] = v_real_out;    
      data_imag[i+N_DIV_2] = v_imag_out;    
      data_exp[i+N_DIV_2] = v_exp_out;      
                 
    }

    ////dump for test
    //if(data_ldn == 8) {
    //  for(i = 0; i < N; i++) {
    //    fprintf(test_file, "%d      %d      %d\n", data_real[i], data_imag[i], data_exp[i]); 
    //  }
    //}    
    
    //calculate the second stage radix-2 butterfly
    for (k1 = 0; k1 < 2; k1++)
    {
      for (i =0; i < N_DIV_4; i++)
      {
      	int u_index;
      	int v_index;
      	
        if (k1 == 0)
        {
        	u_index = i;
        	v_index = i + N_DIV_4;
        	
        	u_real_in = data_real[u_index];
        	u_imag_in = data_imag[u_index];
        	u_exp_in = data_exp[u_index];
        	v_real_in = data_real[v_index];
        	v_imag_in = data_imag[v_index];
        	v_exp_in = data_exp[v_index];       
        }
        else
        {
        	u_index = i+N_DIV_2;
        	v_index = i+N_DIV_2 + N_DIV_4;
        	
        	u_real_in = data_real[u_index];
        	u_imag_in = data_imag[u_index];
        	u_exp_in = data_exp[u_index];
        	
        	v_real_in = data_imag[v_index]; 
        	v_imag_in = -data_real[v_index];
        	v_exp_in = data_exp[v_index];                    
        }
        //input scaling                                                                            
        int common_exp_in = input_scaling(u_real_in, u_imag_in, u_exp_in, v_real_in, v_imag_in, v_exp_in, MAN_WIDTH);
             
        //butterfly algorithm                                                                       
        //bit width increase 1                                                                      
        u_real_out = u_real_in + v_real_in;                                                           
        u_imag_out = u_imag_in + v_imag_in;                                                           
        v_real_out = u_real_in - v_real_in;                                                           
        v_imag_out = u_imag_in - v_imag_in;   
        
        //ouput scaling and rounding                                            
        u_exp_out = output_scaling(u_real_out, u_imag_out, common_exp_in);  
        v_exp_out = output_scaling(v_real_out, v_imag_out, common_exp_in);  
                                                                     
        //output results               
        data_real[u_index] = u_real_out;    
        data_imag[u_index] = u_imag_out;    
        data_exp[u_index] = u_exp_out;      
        data_real[v_index] = v_real_out;    
        data_imag[v_index] = v_imag_out;    
        data_exp[v_index] = v_exp_out;                   
      }
    }

    //dump for test
    //if(data_ldn == 8) {
    //  for(i = 0; i < N; i++) {
    //    fprintf(test_file, "%d      %d      %d\n", data_real[i], data_imag[i], data_exp[i]); 
    //  }
    //}    

    //multiply by twiddle factors
    //results stored into output buffer
    for (k1 = 0; k1 < 2; k1++)
    {
      for (k2 = 0; k2 < 2; k2++)
      {
        for (n3 = 0; n3 < N_DIV_4; n3++)
        {
        	int n;
	        //n = n3 * (k1 + 2*k2);
          switch (k1+(k2 << 1)) {
            case 0: n = 0;             break;
            case 1: n = n3;            break;
            case 2: n = n3 << 1;       break;
            case 3: n = n3 + (n3 << 1);  break;
          } 
          double phi = n*ph0;  
          int addr = n3 + (k1 << (data_ldn-1)) + (k2 << (data_ldn-2));
          
          //convert float point coefficient to fixed-point coefficient           
          double cos_val = cos(phi);                                           
          double sin_val = sin(phi);                                           
          int twid_real = float2fixed_satrnd(cos_val, COEF_WIDTH-1, COEF_WIDTH); 
          int twid_imag = float2fixed_satrnd(sin_val, COEF_WIDTH-1, COEF_WIDTH); 

	        //multiply input data with twiddle factors
	        //result width: (MAN_WIDTH+1-1)+(COEF_WIDTH-1)+1 or (MAN_WIDTH-1)+(COEF_WIDTH+1-1)+1
	        //=MAN_WIDTH+COEF_WIDTH
	        int temp1 = (data_real[addr] + data_imag[addr]) * twid_real; 
	        int temp2 = data_imag[addr] * (twid_imag + twid_real);
	        int temp3 = data_real[addr] * (twid_imag - twid_real);
	        //cut results to MAN_WIDTH+1 bits
	        int cutbits = COEF_WIDTH-1;
	        temp1 = SymRoundShift(temp1, cutbits);
	        temp2 = SymRoundShift(temp2, cutbits);  
	        temp3 = SymRoundShift(temp3, cutbits);	  
          
          //man_width_m+1 bits adder
          if(data_ldn == 3 || data_ldn == 2) {
            int temp_real, temp_imag;
            twid_mul_r4u0(n, N_DIV_4, data_real[addr], data_imag[addr], temp_real, temp_imag);
	        data_real[addr] = temp_real;
	        data_imag[addr] = temp_imag;            
          }    
          else {  //original code              
	        data_real[addr] = temp1 - temp2;
	        data_imag[addr] = temp1 + temp3;
	      }
	        
	        //output scaling
          data_exp[addr] = output_scaling(data_real[addr], data_imag[addr], data_exp[addr]);       
        }
      }
    }	

    //dump for test
    //if(data_ldn == 3) {
    //  for(i = 0; i < N; i++) {
    //    fprintf(test_file, "%d      %d      %d\n", data_real[i], data_imag[i], data_exp[i]); 
    //  }
    //}    

}

//special processing for the first r2^2 stage multiplication
void twid_mul_r4u0(int r, int n_div_4, int data_real_i, int data_imag_i, int &data_real, int &data_imag)
{
  int m2 = 0;  
  int x_r1;
  int x_r2;
  int x_i1;
  int x_i2;
  
  //data_real_i*sqrt(2)/2, data_imag_i*sqrt(2)/2, coefficient 1.11
  //mul_real = (data_real_i<<<10)+(data_real_i<<<8)+(data_real_i<<<7)+(data_real_i<<<5)+(data_real_i<<<3);
  //mul_imag = (data_imag_i<<<10)+(data_imag_i<<<8)+(data_imag_i<<<7)+(data_imag_i<<<5)+(data_imag_i<<<3);
  //`SYMRND(mul_real, mul_real, 11);
  //`SYMRND(mul_imag, mul_imag, 11);
  
  //coefficient 1.12
  int mul_real = (data_real_i<<11)+(data_real_i<<9)+(data_real_i<<8)+(data_real_i<<6)+(data_real_i<<4);
  int mul_imag = (data_imag_i<<11)+(data_imag_i<<9)+(data_imag_i<<8)+(data_imag_i<<6)+(data_imag_i<<4);  
  int temp_real = SymRoundShift(mul_real, 12);
  int temp_imag = SymRoundShift(mul_imag, 12);
  
  //default values
  data_real = 0;
  data_imag = 0;
    
	if(r >= n_div_4) {
	  r = r - n_div_4;
	  m2 = 1;
  }  
	 
	//cos_table: 1, sqrt(2)/2; sin_table: 0, sqrt(2)/2       
	if (m2 == 0) { 
	  //twid_real = cos_table_m[r];
	  //twid_imag = -sin_table_m[r];
	  x_r1 = (r == 0) ? data_real_i : temp_real;  //x_r1 = data_real_i*twid_real
	  x_r2 = (r == 0) ? 0 : temp_imag;            //x_r2 = -data_imag_i*twid_imag
	  x_i1 = (r == 0) ? 0 : (-temp_real);         //x_i1 = data_real_i*twid_imag
	  x_i2 = (r == 0) ? data_imag_i : temp_imag;  //x_i2 = data_imag_i*twid_real
	}
	else {
	  //twid_real = -sin_table_m[r];
	  //twid_imag = -cos_table_m[r];
	  x_r1 = (r == 0) ? 0 : (-temp_real);
	  x_r2 = (r == 0) ? data_imag_i : temp_imag;
	  x_i1 = (r == 0) ? (-data_real_i) : (-temp_real);
	  x_i2 = (r == 0) ? 0 : (-temp_imag); 
	}   
	
	data_real = x_r1 + x_r2;
	data_imag = x_i1 + x_i2;  
}

// bit reverse function, hybrid float point version
void revbin_permute_e(int *data_real, int *data_imag, int *data_exp, unsigned long ldn)
{
  //Writing out the normalized transform values in bit reversed order
  int                        temp_data_real[1<<MAX_ADDR_BITS];
  int                        temp_data_imag[1<<MAX_ADDR_BITS];
  int                        temp_data_exp[1<<MAX_ADDR_BITS];
  unsigned long              i, j, n;
  unsigned long              reverse_index;

  n = (1UL<<ldn);
  
  //cout << "Writing the transform values..." << endl;
  for (i = 0; i < n; i++)
  {
     unsigned long x = i;
     reverse_index = 0;
     for(j = 0; j < ldn; j++)
     {
       reverse_index = reverse_index << 1; 
       reverse_index = reverse_index + (x&0x1); //parentheses is needed to clarify
       x = x >> 1;   
     }          
     temp_data_real[i] = data_real[reverse_index];
     temp_data_imag[i] = data_imag[reverse_index];
     temp_data_exp[i] = data_exp[reverse_index];
  }
     
  //re-store the result in array f
  for (i = 0; i < n; i++)
  {
    //f[i] = temp_result[i];
    data_real[i] = temp_data_real[i];
    data_imag[i] = temp_data_imag[i];
    data_exp[i] = temp_data_exp[i];
  }  
}

int input_scaling(int &u_real, int &u_imag, int u_exp, int &v_real, int &v_imag, int v_exp, int man_width_m)
/*
  inputs:
    u_real: real part of the first butterfly input
    u_imag: imaginary part of the first butterfly input
    u_exp:  exponent of the first butterfly input
    v_real: real part of the second butterfly input
    v_imag: imaginary part of the second butterfly input
    v_exp:  exponent of the second butterfly input   
    man_width_m: bit width of mantissa
  outputs:
    u_real: aligned real part of the first butterfly input
    u_imag: aligned imaginary part of the first butterfly input
    u_exp:  aligned exponent of the first butterfly input
    v_real: aligned real part of the second butterfly input
    v_imag: aligned imaginary part of the second butterfly input
    v_exp:  aligned exponent of the second butterfly input   
  return value:
    common exponent     
*/
{
    int max_exp_in;
    
    //get the first input
    int bf2_r_in1 = u_real;
    int bf2_i_in1 = u_imag;
    int data_exp_in1 = u_exp;    
    //get the second input
    int bf2_r_in2 = v_real;
    int bf2_i_in2 = v_imag;
    int data_exp_in2 = v_exp;
       
    //input scaling
    if (data_exp_in1 >= data_exp_in2)
    {
      max_exp_in = data_exp_in1;
      int cutbits = data_exp_in1 - data_exp_in2;
      if (cutbits < man_width_m) {
        bf2_r_in2 = SymRoundShift(bf2_r_in2, cutbits); 
        bf2_i_in2 = SymRoundShift(bf2_i_in2, cutbits); 
      }
      else {
        bf2_r_in2 = 0;
        bf2_i_in2 = 0;
      }  
    }
    else
    {
      max_exp_in = data_exp_in2;
      int cutbits = data_exp_in2 - data_exp_in1;
      if (cutbits < man_width_m) {
        bf2_r_in1 = SymRoundShift(bf2_r_in1, cutbits);
        bf2_i_in1 = SymRoundShift(bf2_i_in1, cutbits); 
      }
      else {
        bf2_r_in1 = 0;
        bf2_i_in1 = 0;
      }
    }
    
    u_real = bf2_r_in1;
    u_imag = bf2_i_in1;
    v_real = bf2_r_in2;
    v_imag = bf2_i_in2;
    
    return max_exp_in;
}

int output_scaling(int &x_r, int &x_i, int data_exp)
/*
  inputs:
    x_r
    x_i
  outputs:
    x_r
    x_i
  return valuse
    adjusted exponent
*/
{
    int abs_max_man = (1 << (MAN_WIDTH - 1)) - 1;    
    int abs_x_r = (x_r >= 0) ? x_r : -x_r;
    int abs_x_i = (x_i >= 0) ? x_i : -x_i;
    int max_x = (abs_x_r >= abs_x_i) ? abs_x_r : abs_x_i;
    if (max_x > abs_max_man)
    {
      data_exp = data_exp + 1;
      x_r = SymRoundShift(x_r, 1);
      x_i = SymRoundShift(x_i, 1);
    }
    
    return data_exp;
}
