clc;
clear all;
close all;

N = 1536;
N1 = 3;
N2 = 512;

%generate random input 
x = randn(1, N) + j*randn(1, N);

%normal fft
X1 = fft(x, N);

%cooley-tukey fft
X2 = cooley_tukey(x, N, N1, N2);

diff = abs(X1 - X2);

plot(diff);