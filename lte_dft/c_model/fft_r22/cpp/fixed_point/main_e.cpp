#include <stdio.h>
#include "fast_fft_e.h"
#include "fft_fixed_point.h"
#include "make_lut.h"
#include "macros.h" 

void main(int argc, char *argv[])
{
  char                file_name[200];
  FILE                *_source_file;
  FILE                *_sink_bfp_file;  
  double              x_r, x_i;
  unsigned long       i;
  unsigned long       N = 1UL << DATA_LDN;
       
  //semi float point fft algorithm
  int  data_real[1UL << DATA_LDN];
  int  data_imag[1UL << DATA_LDN];
  int  data_exp[1UL << DATA_LDN];
  
  sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");  
  _source_file = fopen(file_name, "r");
  for (i = 0; i < N; i++) 
  {
    fscanf(_source_file, "%Lf  %Lf\n", &x_r, &x_i);
    //convert float point data to fixed point data
    int temp_real = float2fixed_satrnd(x_r, IN_PTPOS, IN_WIDTH);
    int temp_imag = float2fixed_satrnd(x_i, IN_PTPOS, IN_WIDTH);
    data_real[i] = temp_real;
    data_imag[i] = temp_imag;
    
    //convert fixed point data to hybrid float point data
    fixed2bfp(data_real[i], data_imag[i], data_exp[i], IN_PTPOS, IN_WIDTH, MAN_WIDTH, EXP_WIDTH);    
  } 
  fclose(_source_file);  
  
  //do hybrid float point radix-2^2 FFT
  fast_fft_e(data_real, data_imag, data_exp, DATA_LDN, -1);

  //output ordinary FFT results
  sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_BFP_FILE, N, ".dat");
  _sink_bfp_file = fopen(file_name,"wt+");  
  for (i = 0; i < N; i++)
  {
    double dlb_data_real;
    double dlb_data_imag;   

    //convert hybrid float point to fixed-point data
    bfp2fixed(data_real[i], data_imag[i], data_exp[i], MAN_WIDTH, OUT_PTPOS, OUT_WIDTH);
    //convert fixed-point to float-point data
    dlb_data_real = fixed2float(data_real[i], OUT_PTPOS);
    dlb_data_imag = fixed2float(data_imag[i], OUT_PTPOS);
    
    fprintf(_sink_bfp_file,"%16.8f      %16.8f\n",dlb_data_real, dlb_data_imag);
  }  
  fclose(_sink_bfp_file); 

  main_make_lut();

  getchar();
}

