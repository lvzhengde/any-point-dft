clc;
clear all;
close all;

FIR_COEF          = './lut/fir_coef.dat';
%over sampling factor and polyphase length
os= 64; 
polyphase= 6;
%get filter coefficients from file
fid_fir_coef = fopen(FIR_COEF, 'r');
fir_coef=fscanf(fid_fir_coef,'%g',inf);
fclose(fid_fir_coef);

%calculate frequence response by 2^20 fft
padded_fir_coef = [fir_coef', zeros(1, 2^20-length(fir_coef))];
H_lpf = fft(padded_fir_coef);

%reserve frequence response [1:2^20/2/os+1]
len = 2^20/2/os;
freq_resp = H_lpf(1:len+1);

%calculate frequence response of linear interpolator
intp_freq_resp = (sinc([0:1/(os*2)/len:1/(os*2)])).^2;

%calculate amplitude of frequence compensation factor
freq_resp = freq_resp .* intp_freq_resp;
amp_comp_factor = 10./abs(freq_resp);


