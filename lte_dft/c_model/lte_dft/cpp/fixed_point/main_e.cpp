#include <stdio.h>
#include "macros.h"
#include "fast_fft_e.h"
#include "fft_fixed_point.h"
#include "dft_proc_e.h" 

#define  FILE_PREFIX           ("../../..")
#define  SOURCE_FILE           ("/data/input/dft_gen")
#define  SINK_FIXED_FILE       ("/data/output/dft_sink_fixed")

#define  DEBUG_FILE            ("/data/temp/dbg")

int lte_dft_len[] = {12, 24, 36, 48, 60, 72, 96, 108, 120, 144, 180, 192, 216, 240, 
  288, 300, 324, 360, 384, 432, 480, 540, 576, 600, 648, 720, 768, 864, 900,
  960, 972, 1080, 1152, 1200, 1296, 1536};
  
int lte_fft_len[] = {16, 32, 64, 64, 128, 128, 128, 256, 256, 256, 256, 256, 512, 512,
  512, 512, 512, 512, 512, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024,2048, 2048,
  2048, 2048, 2048, 2048, 2048, 2048, 2048};

int lte_fft_ldn[] = {4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8, 8, 9, 9,
  9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10,11, 11,
  11, 11, 11, 11, 11, 11, 11};

void main(int argc, char *argv[])
{
  char    file_name[200];
  FILE    *_source_file;
  FILE    *_sink_fixed_file;  
  FILE    *_debug_file;
  int     dft_buf_re[1536];
  int     dft_buf_im[1536];   
  int     fft_buf_re[2048];    
  int     fft_buf_im[2048]; 
  int     fft_buf_exp[2048];           
  double  x_r, x_i;
  int     i; 
  int     k;
  int     N;
  int     ldn;
  
  int     dft_len;
  int     dft_index;
  bool    single_point;
  bool    single_point_2n;
  bool    all_point;
  
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
      case 8:    single_point_2n = true; ldn = 3;  break;
      case 16:   single_point_2n = true; ldn = 4;  break;        
      case 32:   single_point_2n = true; ldn = 5;  break;  
      case 64:   single_point_2n = true; ldn = 6;  break; 
      case 128:  single_point_2n = true; ldn = 7;  break;
      case 256:  single_point_2n = true; ldn = 8;  break;   
      case 512:  single_point_2n = true; ldn = 9;  break; 
      case 1024: single_point_2n = true; ldn = 10; break; 
      case 2048: single_point_2n = true; ldn = 11; break;   
      default:   single_point_2n = false;                                             
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
    N = dft_len;  	
    sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");  
    _source_file = fopen(file_name, "r");
    for (i = 0; i < N; i++) 
    {
      fscanf(_source_file, "%Lf  %Lf\n", &x_r, &x_i);
      //convert float point data to fixed point data
      int temp_real = float2fixed_satrnd(x_r, FFT_IN_PTPOS, FFT_IN_WIDTH);
      int temp_imag = float2fixed_satrnd(x_i, FFT_IN_PTPOS, FFT_IN_WIDTH);
      dft_buf_re[i] = temp_real;
      dft_buf_im[i] = temp_imag;    
    }
    fclose(_source_file);  
    
    //preprocessing
    ldn = lte_fft_ldn[dft_index];
    preproc_e(dft_buf_re, dft_buf_im, fft_buf_re, fft_buf_im, N, ldn);

    //for test
	  //FILE *test_file;
	  //test_file = fopen(TEST_FILE, "wt+");
	  //for(i = 0; i < (1<<ldn); i++) {
	  //	fprintf(test_file, "%d      %d\n", fft_buf_re[i], fft_buf_im[i]);
	  //}
	  //fclose(test_file);

    //convert fixed-point data to semi-float point data
    for(i = 0; i < (1<<ldn); i++) {
      fixed2bfp(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], FFT_IN_PTPOS, FFT_IN_WIDTH, MAN_WIDTH, EXP_WIDTH); 
	  
	  //if(i == 397) {
	  //	  int xx;
	  //	  xx = i;
	  //}
    }

	//debug, dump results of fft
    //sprintf(file_name, "%s%s%s%d%s", FILE_PREFIX, DEBUG_FILE, "_prep10bit_bfp", N, ".dat");
    //_debug_file = fopen(file_name,"wt+");  
    //for (i = 0; i < (1<<ldn); i++)
    //{
      //double dlb_data_real;
      //double dlb_data_imag;   

      //bfp2fixed(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], MAN_WIDTH, FFT_IN_PTPOS, FFT_IN_WIDTH);

      ////convert fixed-point to float-point data
      //dlb_data_real = fixed2float(fft_buf_re[i], FFT_IN_PTPOS);
      //dlb_data_imag = fixed2float(fft_buf_im[i], FFT_IN_PTPOS);
      
      //fprintf(_debug_file,"%16.8f      %16.8f\n",dlb_data_real, dlb_data_imag);
	  //fprintf(_debug_file,"%d      %d      %d\n",fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i]);
    //}  
    //fclose(_debug_file);  
    
    //fast radix-2^2 FFT
    fast_fft_e(fft_buf_re, fft_buf_im, fft_buf_exp, ldn, -1, BIT_REV);
    
    //FILE *test_file;
	  //test_file = fopen(TEST_FILE, "wt+");
	  //for(i = 0; i < (1<<ldn); i++) {
	  //	fprintf(test_file, "%d      %d     %d\n", fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i]);
	  //}
	  //fclose(test_file);
    
	//debug, dump results of fft
    //sprintf(file_name, "%s%s%s%d%s", FILE_PREFIX, DEBUG_FILE, "_fft_fixed", N, ".dat");
    //_debug_file = fopen(file_name,"wt+");  
    //for (i = 0; i < (1<<ldn); i++)
    //{
    //  double dlb_data_real;
    //  double dlb_data_imag;   

    //  bfp2fixed(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], MAN_WIDTH, FFT_OUT_PTPOS, FFT_OUT_WIDTH);

    //  //convert fixed-point to float-point data
    //  dlb_data_real = fixed2float(fft_buf_re[i], FFT_OUT_PTPOS);
    //  dlb_data_imag = fixed2float(fft_buf_im[i], FFT_OUT_PTPOS);
    //  
    //  fprintf(_debug_file,"%16.8f      %16.8f\n",dlb_data_real, dlb_data_imag);
    //}  
    //fclose(_debug_file); 
    
    //postprocessing
    //convert semi-float data to fixed-point
    for(i = 0; i < (1<<ldn); i++) {
      bfp2fixed(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], MAN_WIDTH, FFT_OUT_PTPOS, FFT_OUT_WIDTH);    	
    }
    
    
    //FILE *test_file;
	  //test_file = fopen(TEST_FILE, "wt+");
	  //for(i = 0; i < (1<<ldn); i++) {
	  //	fprintf(test_file, "%d      %d\n", fft_buf_re[i], fft_buf_im[i]);
	  //}
	  //fclose(test_file);
    
    postproc_e(fft_buf_re, fft_buf_im, dft_buf_re, dft_buf_im, N, ldn, BIT_REV);
    
    
    //output ordinary dft results
    sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_FIXED_FILE, N, ".dat");
    _sink_fixed_file = fopen(file_name,"wt+");  
    for (i = 0; i < N; i++)
    {
      double dlb_data_real;
      double dlb_data_imag;   
    
      //convert fixed-point to float-point data
      dlb_data_real = fixed2float(dft_buf_re[i], FFT_OUT_PTPOS);
      dlb_data_imag = fixed2float(dft_buf_im[i], FFT_OUT_PTPOS);
      
      fprintf(_sink_fixed_file,"%16.8f      %16.8f\n",dlb_data_real, dlb_data_imag);
    }  
    fclose(_sink_fixed_file); 
  }
  
  //single point, for 2^n point fft
   if(single_point_2n == true) {
    N = dft_len;  	
    sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");  
    _source_file = fopen(file_name, "r");
    for (i = 0; i < N; i++) 
    {
      fscanf(_source_file, "%Lf  %Lf\n", &x_r, &x_i);
      //convert float point data to fixed point data
      int temp_real = float2fixed_satrnd(x_r, FFT_IN_PTPOS, FFT_IN_WIDTH);
      int temp_imag = float2fixed_satrnd(x_i, FFT_IN_PTPOS, FFT_IN_WIDTH);
      fft_buf_re[i] = temp_real;
      fft_buf_im[i] = temp_imag; 
      
      fixed2bfp(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], FFT_IN_PTPOS, FFT_IN_WIDTH, MAN_WIDTH, EXP_WIDTH);    
    }
    fclose(_source_file);  
        
    //fast radix-2^2 FFT
    fast_fft_e(fft_buf_re, fft_buf_im, fft_buf_exp, ldn, -1, BIT_REV);
    
    //output ordinary FFT results
    sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_FIXED_FILE, N, ".dat");
    _sink_fixed_file = fopen(file_name,"wt+");  
    for (i = 0; i < N; i++)
    {
      double dlb_data_real;
      double dlb_data_imag;   
    
      //convert hybrid float point to fixed-point data
      bfp2fixed(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], MAN_WIDTH, FFT_OUT_PTPOS, FFT_OUT_WIDTH);
      //convert fixed-point to float-point data
      dlb_data_real = fixed2float(fft_buf_re[i], FFT_OUT_PTPOS);
      dlb_data_imag = fixed2float(fft_buf_im[i], FFT_OUT_PTPOS);
      
      fprintf(_sink_fixed_file,"%16.8f      %16.8f\n",dlb_data_real, dlb_data_imag);
    }  
    fclose(_sink_fixed_file); 
  }
  
  //all point dft processing
  if(all_point == true) {
  	//non-2^n point dft
  	for(k = 0; k < 36; k++) {
      N = lte_dft_len[k]; 
      sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");  
      _source_file = fopen(file_name, "r");
      for (i = 0; i < N; i++) 
      {
        fscanf(_source_file, "%Lf  %Lf\n", &x_r, &x_i);
        //convert float point data to fixed point data
        int temp_real = float2fixed_satrnd(x_r, FFT_IN_PTPOS, FFT_IN_WIDTH);
        int temp_imag = float2fixed_satrnd(x_i, FFT_IN_PTPOS, FFT_IN_WIDTH);
        dft_buf_re[i] = temp_real;
        dft_buf_im[i] = temp_imag;    
      }
      fclose(_source_file);  
      
      //preprocessing
      ldn = lte_fft_ldn[k];
      preproc_e(dft_buf_re, dft_buf_im, fft_buf_re, fft_buf_im, N, ldn);
      //convert fixed-point data to semi-float point data
      for(i = 0; i < (1<<ldn); i++) {
        fixed2bfp(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], FFT_IN_PTPOS, FFT_IN_WIDTH, MAN_WIDTH, EXP_WIDTH);       	
      }
      
      //fast radix-2^2 FFT
      fast_fft_e(fft_buf_re, fft_buf_im, fft_buf_exp, ldn, -1, BIT_REV);
      
      //postprocessing
      //convert semi-float data to fixed-point
      for(i = 0; i < (1<<ldn); i++) {
        bfp2fixed(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], MAN_WIDTH, FFT_OUT_PTPOS, FFT_OUT_WIDTH);    	
      }
      postproc_e(fft_buf_re, fft_buf_im, dft_buf_re, dft_buf_im, N, ldn, BIT_REV);
      
      
      //output ordinary dft results
      sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_FIXED_FILE, N, ".dat");
      _sink_fixed_file = fopen(file_name,"wt+");  
      for (i = 0; i < N; i++)
      {
        double dlb_data_real;
        double dlb_data_imag;   
      
        //convert fixed-point to float-point data
        dlb_data_real = fixed2float(dft_buf_re[i], FFT_OUT_PTPOS);
        dlb_data_imag = fixed2float(dft_buf_im[i], FFT_OUT_PTPOS);
        
        fprintf(_sink_fixed_file,"%16.8f      %16.8f\n",dlb_data_real, dlb_data_imag);
      }  
      fclose(_sink_fixed_file);   		
  	}
  	
  	//2^n-point fft
  	for(k = 3; k <12; k++) {
      N = (1<<k);
      ldn = k;  	
      sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SOURCE_FILE, N, ".dat");  
      _source_file = fopen(file_name, "r");
      for (i = 0; i < N; i++) 
      {
        fscanf(_source_file, "%Lf  %Lf\n", &x_r, &x_i);
        //convert float point data to fixed point data
        int temp_real = float2fixed_satrnd(x_r, FFT_IN_PTPOS, FFT_IN_WIDTH);
        int temp_imag = float2fixed_satrnd(x_i, FFT_IN_PTPOS, FFT_IN_WIDTH);
        fft_buf_re[i] = temp_real;
        fft_buf_im[i] = temp_imag; 
        
        fixed2bfp(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], FFT_IN_PTPOS, FFT_IN_WIDTH, MAN_WIDTH, EXP_WIDTH);    
      }
      fclose(_source_file);  
          
      //fast radix-2^2 FFT
      fast_fft_e(fft_buf_re, fft_buf_im, fft_buf_exp, ldn, -1, BIT_REV);
      
      //output ordinary FFT results
      sprintf(file_name, "%s%s%d%s", FILE_PREFIX, SINK_FIXED_FILE, N, ".dat");
      _sink_fixed_file = fopen(file_name,"wt+");  
      for (i = 0; i < N; i++)
      {
        double dlb_data_real;
        double dlb_data_imag;   
      
        //convert hybrid float point to fixed-point data
        bfp2fixed(fft_buf_re[i], fft_buf_im[i], fft_buf_exp[i], MAN_WIDTH, FFT_OUT_PTPOS, FFT_OUT_WIDTH);
        //convert fixed-point to float-point data
        dlb_data_real = fixed2float(fft_buf_re[i], FFT_OUT_PTPOS);
        dlb_data_imag = fixed2float(fft_buf_im[i], FFT_OUT_PTPOS);
        
        fprintf(_sink_fixed_file,"%16.8f      %16.8f\n",dlb_data_real, dlb_data_imag);
      }  
      fclose(_sink_fixed_file);   		
  	}
  }   
  

  getchar();
}
