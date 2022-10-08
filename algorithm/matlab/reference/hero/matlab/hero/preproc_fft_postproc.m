function symbol_f_any = preproc_fft_postproc(data_len, fft_len, symbol_t_any, polyphase, os, polyfilter_lut)
%   preprocessing, fft and postprocessing for any point dft
%   outputs:    
%   symbol_f_any      clipped and shifted fft results

%   inputs:     
%   data_len          data length for any-point dft
%   fft_len           fft length for the nearest caculatible 2^n-point or 3*2^n-point FFT
%   symbol_t_any      time domain data for any point DFT
%   polyphase         tap length for polyphase filter
%   os                upsampling times for polyphase filter
%   polyfilter_lut    cofficient lut for polyphase filter
symbol_t_dup = [symbol_t_any symbol_t_any];
src_in=[symbol_t_any symbol_t_dup(1:polyphase+1)];

%sample rate conversion
acc=polyphase+0.5;
src_memory.buffer=zeros(1,polyphase);
src_memory.acc=acc;
src_out=[];
cnst_delta=data_len/fft_len;

for i=1:length(src_in)-1
    [src_out_t,src_memory] = sample_rate_conv(src_in(i),src_in(i+1),cnst_delta,os,polyphase,polyfilter_lut,src_memory);
    src_out=[src_out,src_out_t];
end

symbol_t_2n=src_out(1:fft_len);

%do fft
symbol_f_2n=fft(symbol_t_2n);

low_freq     = symbol_f_2n(1:floor(data_len/2)+1); 
high_freq    = symbol_f_2n(fft_len-data_len+floor(data_len/2)+2:fft_len);
symbol_f_any = [low_freq   high_freq];
