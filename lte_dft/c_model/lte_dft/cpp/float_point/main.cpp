#include <stdio.h>
#include "fast_fft_x.h"
#include "dft_proc.h"

#define  FILE_PREFIX           ("F:/project/lte_dft/c_model/lte_dft")
#define  SOURCE_FILE           ("/data/input/dft_gen")
#define  SINK_FLOAT_FILE       ("/data/output/dft_sink_float")
#define  SINK_MAT_FILE         ("/data/output/dft_sink_mat")

#define  DEBUG_FILE            ("/data/temp/dbg")

#define  BIT_REV               (true)

int lte_dft_len[] = {12, 24, 36, 48, 60, 72, 96, 108, 120, 144, 180, 192, 216, 240, 
  288, 300, 324, 360, 384, 432, 480, 540, 576, 600, 648, 720, 768, 864, 900,
  960, 972, 1080, 1152, 1200, 1296, 1536};
  
int lte_fft_len[] = {16, 32, 64, 64, 128, 128, 128, 256, 256, 256, 256, 256, 512, 512,
  512, 512, 512, 512, 512, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024,2048, 2048,
  2048, 2048, 2048, 2048, 2048, 2048, 2048};

int lte_fft_ldn[] = {4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8, 8, 9, 9,
  9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10,11, 11,
  11, 11, 11, 11, 11, 11, 11};
  
void main(void)
{
  char                file_name[200];
  FILE                *_in_file;
  FILE                *_sink_float_file;
  FILE                *_sink_mat_file;  
  FILE                *_debug_file;
  int                 ret_val;
  complex<double>     dft_buf[1536];
  complex<double>     fft_buf[2048];  
  double              x_r, x_i;
  int                 i;
  int                 k;
  int                 N;
  int                 M;
  int                 ldn;
  
  int  dft_len;
  int  dft_index;
  bool single_point;
  bool single_point_2n;
  bool all_point;
  
  //input control parameters
  printf("Please input dft length: \n");
  scanf("%d", &dft_len); 
  
  single_point = false;
  single_point_2n = false;
  all_point = false;
  
  for(i = 0; i < 36; i++) {
  	if(dft_len == lte_dft_len[i]) {
  		dft_index = i;
  		single_point = true;
  		break;
  	}
  }
  
  if(single_point == false) {
    switch(dft_len) {
      case 8:     single_point_2n = true; ldn = 3; break;
      case 16:    single_point_2n = true; ldn = 4; break;        
      case 32:    single_point_2n = true; ldn = 5; break;  
      case 64:    single_point_2n = true; ldn = 6; break; 
      case 128:   single_point_2n = true; ldn = 7; break;
      case 256:   single_point_2n = true; ldn = 8; break;   
      case 512:   single_point_2n = true; ldn = 9; break; 
      case 1024:  single_point_2n = true; ldn = 10;break; 
      case 2048:  single_point_2n = true; ldn = 11;break;   
      default:    single_point_2n = false;                                             
    }
  }
  
  char temp = 'Y';
  if(single_point == false && single_point_2n == false) {
    getchar();
  	printf("Do you want to do all these dft transformation? \n Y or N:\n");
  	scanf("%c", &temp);
  	if (temp == 'Y' || temp == 'y')
  		all_point = true;
  	else
  		all_point = false;
  }
  
  //single point dft processing
  if(single_point == true) {
    //input data
    N = dft_len;
    sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");
    _in_file = fopen(file_name, "r");
    for (i = 0; i < N; i++) 
    {
      ret_val = fscanf(_in_file, "%lf  %lf\n", &x_r, &x_i);    
      dft_buf[i].real = x_r;
      dft_buf[i].imag = x_i;
    }
    fclose(_in_file);
    
    //dft transformation
    ldn = lte_fft_ldn[dft_index];
    preproc(dft_buf, fft_buf, N, ldn);
    fast_fft_x(fft_buf, ldn, -1, BIT_REV);

	//debug, dump results of preprocessing
    sprintf(file_name, "%s%s%s%d%s", FILE_PREFIX, DEBUG_FILE, "_fft_float", N, ".dat");
    _debug_file = fopen(file_name,"wt+");  
    for (i = 0; i < (1<<ldn); i++)
    {
      double dlb_data_real;
      double dlb_data_imag;   
    
      //convert fixed-point to float-point data
      dlb_data_real = fft_buf[i].real; 
      dlb_data_imag = fft_buf[i].imag; 
      
      fprintf(_debug_file,"%16.8f      %16.8f\n",dlb_data_real, dlb_data_imag);
    }  
    fclose(_debug_file); 

    postproc(fft_buf, dft_buf, N, ldn, BIT_REV);
    
    //output DFT results
    sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_FLOAT_FILE, N, ".dat");   
    _sink_float_file = fopen(file_name,"wt+");  
    for (i = 0; i < N; i++)
    {
      fprintf(_sink_float_file,"%16.8f      %16.8f\n",dft_buf[i].real, dft_buf[i].imag);
    }  
    fclose(_sink_float_file);
  }
  
  //single point dft processing, for 2^n point fft
  if(single_point_2n == true) {
    //input data
    N = dft_len;
    sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");
    _in_file = fopen(file_name, "r");
    for (i = 0; i < N; i++) 
    {
      ret_val = fscanf(_in_file, "%lf  %lf\n", &x_r, &x_i);    
      fft_buf[i].real = x_r;
      fft_buf[i].imag = x_i;
    }
    fclose(_in_file);
    
    //dft transformation
    fast_fft_x(fft_buf, ldn, -1, BIT_REV);

    //output DFT results
    sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_FLOAT_FILE, N, ".dat");   
    _sink_float_file = fopen(file_name,"wt+");  
    for (i = 0; i < N; i++)
    {
      fprintf(_sink_float_file,"%16.8f      %16.8f\n",fft_buf[i].real, fft_buf[i].imag);
    }  
    fclose(_sink_float_file);
  }
    
  //all point dft processing
  if(all_point == true) {
  	for(k = 0; k < 36; k++) {
      //input data
      N = lte_dft_len[k];
      sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");
      _in_file = fopen(file_name, "r");
      for (i = 0; i < N; i++) 
      {
        ret_val = fscanf(_in_file, "%lf  %lf\n", &x_r, &x_i);    
        dft_buf[i].real = x_r;
        dft_buf[i].imag = x_i;
      }
      fclose(_in_file);
      
      //dft transformation
      ldn = lte_fft_ldn[k];
      preproc(dft_buf, fft_buf, N, ldn);
      fast_fft_x(fft_buf, ldn, -1, BIT_REV);
      postproc(fft_buf, dft_buf, N, ldn, BIT_REV);
      
      //output DFT results
      sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_FLOAT_FILE, N, ".dat");   
      _sink_float_file = fopen(file_name,"wt+");  
      for (i = 0; i < N; i++)
      {
        fprintf(_sink_float_file,"%16.8f      %16.8f\n",dft_buf[i].real, dft_buf[i].imag);
      }  
      fclose(_sink_float_file);
    }
    
  	//2^n-point fft
  	for(k = 3; k <12; k++) {
      N = (1<<k);
      ldn = k;  	
      sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");
      _in_file = fopen(file_name, "r");
      for (i = 0; i < N; i++) 
      {
        ret_val = fscanf(_in_file, "%lf  %lf\n", &x_r, &x_i);    
        fft_buf[i].real = x_r;
        fft_buf[i].imag = x_i;
      }
      fclose(_in_file);
      
      //dft transformation
      fast_fft_x(fft_buf, ldn, -1, BIT_REV);
      
      //output DFT results
      sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_FLOAT_FILE, N, ".dat");   
      _sink_float_file = fopen(file_name,"wt+");  
      for (i = 0; i < N; i++)
      {
        fprintf(_sink_float_file,"%16.8f      %16.8f\n",fft_buf[i].real, fft_buf[i].imag);
      }  
      fclose(_sink_float_file);
  	}    
  }  
  
  getchar();
}  
