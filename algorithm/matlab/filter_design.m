clc;
clear all;
close all;

mkdir('./filter');
FIR_COEF          = './filter/fir_coef.dat';

os= 64; 
polyphase= 6;

%transition band
ibf=0.350;
n=os*polyphase-1;
f = [0 (1.0-ibf)/os (1.0+ibf)/os 1];
m=[1 1 0 0];
w=[1 1000000]; %[1 10000];
fir_coef=os*remez(n,f,m,w);

%add window
filter_window = kaiser(os*polyphase,3.8);
fir_coef = fir_coef .* filter_window';
%dump fir coefficients to file
fid_fir_coef = fopen(FIR_COEF, 'wt');
fprintf(fid_fir_coef, '%16.8f\n', fir_coef);
fclose(fid_fir_coef);

freqz(fir_coef);

