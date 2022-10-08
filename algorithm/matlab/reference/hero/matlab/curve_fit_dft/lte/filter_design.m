clc;
clear all;
close all;

polyphase_window = 3;

os= 32;
polyphase= 2*polyphase_window;
%transition band
ibf= 0.350;
n=os*polyphase-1;
f = [0 (1.0-ibf)/os (1.0+ibf)/os 1];
m=[1 1 0 0];
w=[1 1000];
fir_coef=os*remez(n,f,m,w);
    
%add window
ham = kaiser(os*polyphase,3.8);
fir_coef = fir_coef .* ham';

%calculate frequence response by 2^20 fft
padded_fir_coef = [fir_coef, zeros(1, 2^20-length(fir_coef))];
H_lpf = fft(padded_fir_coef);

%reserve frequence response [1:2^20/2/32+1]
len = 2^20/2/32;
freq_resp = H_lpf(1:len+1);

%calculate frequence response of linear interpolator
intp_freq_resp = (sinc([0:1/64/len:1/64])).^2;

%calculate amplitude of frequence compensation factor
freq_resp = freq_resp .* intp_freq_resp;
amp_comp_factor = 10./abs(freq_resp);


