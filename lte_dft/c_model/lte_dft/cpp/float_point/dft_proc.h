//header file for dft preprocessing and postprocessing

#ifndef _DFT_PROC_H_
#define _DFT_PROC_H_

#include "complex.h"

void preproc(complex<double> *din, complex<double> *dout, int dft_len, int ldn);
void postproc(complex<double> *din, complex<double> *dout, int dft_len, int ldn, bool bit_rev);
int  bit_reverse(int x, int ldn);

#endif // _DFT_PROC_H_ 
