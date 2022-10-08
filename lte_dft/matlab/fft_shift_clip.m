function symbol_f_any = fft_shift_clip(data_len, fft_len, symbol_t_any, polyphase, os, polyfilter_lut)
%   compute clip and shift result for any point DFT
%   outputs:    
%   symbol_f_any      clipped and shifted fft results

%   inputs:     
%   data_len          data length for any-point dft
%   fft_len           fft length for the nearest caculatible 2^n-point FFT
%   symbol_t_any      time domain data for any point DFT
%   polyphase         tap length for polyphase filter
%   os                upsampling times for polyphase filter
%   polyfilter_lut    cofficient lut for polyphase filter
symbol_t_dup = [symbol_t_any symbol_t_any];
srcIn=[symbol_t_any symbol_t_dup(1:polyphase+2)];

%sample rate conversion
acc=polyphase+0.5;
srcMemoryRx.buffer=zeros(1,polyphase);
srcMemoryRx.acc=acc;
srcOut=[];
cnstDelta=data_len/fft_len;
for i=1:length(srcIn)-1
    [srcOut_t,srcMemoryRx] = srcLinearUpSTx(srcIn(i),srcIn(i+1),cnstDelta,os,polyphase,polyfilter_lut,srcMemoryRx);
    srcOut=[srcOut,srcOut_t];
end
symbol_t_2n=srcOut(1:fft_len);

%do fft
symbol_f_2n=fft(symbol_t_2n);

% if mod(data_len,2) == 1
%     r=symbol_f_2n(1:floor((data_len-1)/2+1)); %
%     l=symbol_f_2n(fft_len-ceil((data_len-1)/2)+1:fft_len);%
% else
%     r=symbol_f_2n(1:data_len/2+1); %
%     l=symbol_f_2n(fft_len-data_len/2+2:fft_len);%
% end
% symbol_f_any=[r   l];

low_freq = symbol_f_2n(1:floor(data_len/2)+1); 
high_freq = symbol_f_2n(fft_len-data_len+floor(data_len/2)+2:fft_len);
symbol_f_any=[low_freq   high_freq];
