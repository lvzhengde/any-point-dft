//header file for dft preprocessing and postprocessing

#ifndef _DFT_PROC_E_H_
#define _DFT_PROC_E_H_

void preproc_e(int *din_re, int *din_im, int *dout_re, int *dout_im, int dft_len, int ldn);
void postproc_e(int *din_re, int *din_im, int *dout_re, int *dout_im, int dft_len, int ldn, bool bit_rev);
int  bit_reverse(int x, int ldn);

#endif // _DFT_PROC_H_ 
