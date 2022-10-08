#ifndef __FAST_FFT_X_H_
#define __FAST_FFT_X_H_

#include <math.h>
#include "complex.h"

void fast_fft_x(complex<double> *f, unsigned long ldn, int is, bool bit_rev);
void radix4_stage_x(complex<double> *data, unsigned long data_ldn, int is);
void fft_dif4l_x(complex<double> *f, unsigned long ldn, int is);
void revbin_permute_x(complex<double> *f, unsigned long ldn);

#endif //__FAST_FFT_X_H_
