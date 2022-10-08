#ifndef __FAST_FFT_E_H_
#define __FAST_FFT_E_H_

//#include <systemc.h>
#include <math.h>

void fast_fft_e(int *data_real, int *data_imag, int *data_exp, unsigned long ldn, int is,bool bit_rev);

void radix4_stage_e(int *data_real, int *data_imag, int *data_exp, unsigned long data_ldn, int is);

void twid_mul_r4u0(int r, int n_div_4, int data_real_i, int data_imag_i, int &data_real, int &data_imag);

void revbin_permute_e(int *data_real, int *data_imag, int *data_exp, unsigned long ldn);

int input_scaling(int &u_real, int &u_imag, int u_exp, int &v_real, int &v_imag, int v_exp, int man_width_m);

int output_scaling(int &x_r, int &x_i, int data_exp);

#endif //__FAST_FFT_E_H_
