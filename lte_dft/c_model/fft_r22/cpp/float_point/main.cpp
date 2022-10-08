#include <stdio.h>
#include "fast_fft_x.h"

#define  FILE_PREFIX           ("F:/project/lte_dft/c_model/fft_r22")
#define  SOURCE_FILE           ("/data/input/fft_gen")
#define  SINK_PIPE_FILE        ("/data/output/fft_sink_pipe")
#define  SINK_COMM_FILE        ("/data/output/fft_sink_comm")

#define  DATA_LDN              (5)

void main(void)
{
  char                file_name[80];
  FILE                *_in_file;
  FILE                *_sink_pipe_file;
  FILE                *_sink_comm_file;  
  int                 ret_val;
  complex<double>     buf_fft[1UL << DATA_LDN];
  double              x_r, x_i;
  unsigned long       i;
  unsigned long       N = 1UL << DATA_LDN;
  
  //pipeline fft test
  //input data for pipeline FFT
  sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");
  _in_file = fopen(file_name, "r");
  for (i = 0; i < N; i++) 
  {
    ret_val = fscanf(_in_file, "%lf  %lf\n", &x_r, &x_i);    
    buf_fft[i].real = x_r;
    buf_fft[i].imag = x_i;
  }
  fclose(_in_file);
  
  //do pipeline FFT
  fast_fft_x(buf_fft, DATA_LDN, -1);

  //output pipeline FFT results
  sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_PIPE_FILE, N, ".dat");   
  _sink_pipe_file = fopen(file_name,"wt+");  
  for (i = 0; i < N; i++)
  {
    fprintf(_sink_pipe_file,"%16.8f      %16.8f\n",buf_fft[i].real, buf_fft[i].imag);
  }  
  fclose(_sink_pipe_file);
  
  /*
  //ordinary fft test
  //input data for ordinary FFT
  sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");  
  _in_file = fopen(file_name, "r");
  for (i = 0; i < N; i++) 
  {
    ret_val = fscanf(_in_file, "%lf  %lf\n", &x_r, &x_i);    
    buf_fft[i].real = x_r;
    buf_fft[i].imag = x_i;
  }
  fclose(_in_file);
  
  //do ordinary FFT
  fft_dif4l_x(buf_fft, DATA_LDN, -1);

  //output ordinary FFT results 
  sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_COMM_FILE, N, ".dat");    
  _sink_comm_file = fopen(file_name,"wt+");  
  for (i = 0; i < N; i++)
  {
    fprintf(_sink_comm_file,"%16.8f      %16.8f\n",buf_fft[i].real ,buf_fft[i].imag);
  }  
  fclose(_sink_comm_file); 
  */
  getchar();
}  