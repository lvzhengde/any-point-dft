/*++
  File Name:   fft_fixed_point.h
  Description: declaration of common functions for fixed point operation
--*/

#ifndef __FFT_FIXED_POINT_H_
#define __FFT_FIXED_POINT_H_

//#include <systemc.h>

//qx, qy, qz are positions of fractional points in x, y, z
//just simple truncation, no complex rounding. 
int float2fixed(double x, int q);

double fixed2float(int x, int q);

int fixed_add(int x, int y, int qx, int qy, int qz, int wz); // z = x + y

int fixed_sub(int x, int y, int qx, int qy, int qz, int wz); // z = x - y

int fixed_mul(int x, int y, int qx, int qy, int qz, int wz); // z = x * y

int fixed_div(int x, int y, int qx, int qy, int qz, int wz); // z = x / y

int TruncateShift(int in, int CutBits);

int signed_fixed2fixed(int x, int qx, int qy, int wy); 

//fixed-point operation with saturation and round

int fixed_add_satrnd(int x, int y, int qx, int qy, int qz, int wz); // z = x + y

int fixed_sub_satrnd(int x, int y, int qx, int qy, int qz, int wz); // z = x - y

int fixed_mul_satrnd(int x, int y, int qx, int qy, int qz, int wz); // z = x * y

int fixed_div_satrnd(int x, int y, int qx, int qy, int qz, int wz); // z = x / y

int signed_fixed2fixed_satrnd(int x, int qx, int qy, int wy);

int SymRoundShift(int in, int CutBits); 

int sym_saturation(int in, int data_width);

int barrel_shift(int max_value, int man_width_m);

//fixed to hybrid float, hybrid float to float conversion
int float2fixed_satrnd(double x, int q, int w);

void fixed2bfp(int &data_real, int &data_imag, int &data_exp, int in_ptpos, int in_width, int out_manwidth, int out_expwidth);

void bfp2fixed(int &data_real, int &data_imag, int data_exp, int in_manwidth, int out_ptpos, int out_width);

void bfp2float(int data_real_in, int data_imag_in, int data_exp_in, int in_manwidth, double &data_real_out, double &data_imag_out);

#endif //__FFT_FIXED_POINT_H_
