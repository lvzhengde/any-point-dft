#include <stdio.h>
#include <math.h>
#include "fft_fixed_point.h"
#include "make_lut.h"
#include "macros.h"


void main_make_lut()
{
  //dump look up table to file
  FILE     *_sink_lut_file;
  int      lut[3000];
  int      i;
  //char     str[200];
  
  //sprintf(str, "%s", ROM_FILE_R4U1);  
  //dump lookup table for engine 1
  make_lut(5, lut);
  _sink_lut_file = fopen(ROM_FILE_R4U1,"wt+");  
  for (i = 0; i < 8; i++)
  {
    fprintf(_sink_lut_file,"%d\n",lut[i]);
  }
  fclose(_sink_lut_file);
  
  //dump lookup table for engine 2
  make_lut(7, lut);
  _sink_lut_file = fopen(ROM_FILE_R4U2,"wt+");  
  for (i = 0; i < 32; i++)
  {
    fprintf(_sink_lut_file,"%d\n",lut[i]);
  }
  fclose(_sink_lut_file);
  
  //dump lookup table for engine 3
  make_lut(9, lut);
  _sink_lut_file = fopen(ROM_FILE_R4U3,"wt+");  
  for (i = 0; i < 128; i++)
  {
    fprintf(_sink_lut_file,"%d\n",lut[i]);
  }
  fclose(_sink_lut_file);  

  //dump lookup table for engine 4
  make_lut(11, lut);
  _sink_lut_file = fopen(ROM_FILE_R4U4,"wt+");  
  for (i = 0; i < 512; i++)
  {
    fprintf(_sink_lut_file,"%d\n",lut[i]);
  }
  fclose(_sink_lut_file);  
}

void make_lut(int LDN, int *lut)
{
  double m_pi = 4*atan(1.0);
  int cos_val; 
  int sin_val;
  
  int table_len = 0;

  //make lut table
  int n_div_4 = (1 << LDN) >> 2;
  int data_point = (1 << LDN);
  for (int j = 0; j < n_div_4; j++)
  {
    cos_val = float2fixed_satrnd(cos(2*m_pi*j/data_point), COEF_WIDTH-1, COEF_WIDTH);
    sin_val = float2fixed_satrnd(sin(2*m_pi*j/data_point), COEF_WIDTH-1, COEF_WIDTH);
    int lut_addr = j;
    lut[lut_addr] = (cos_val << COEF_WIDTH) + sin_val;
  }
}

