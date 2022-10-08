function data = cooley_tukey_1st(data, N1, N2)

%   compute first FFT stage of cooley_tukey algorithm, including
%   multiplication of twiddle factors

%   outputs:    
%   data              data output of first cooley_tukey stage

%   inputs:     
%   data              data input
%   N1                fft length N = N1*N2                
%   N2                the second factor


%%do N2 times N1 point FFT
N = N1*N2;
for k = 1:N2
    data_t = [];
    data_f = [];
    %do N1 point FFT
    for m = 1:N1
        data_t = [data_t data((m-1)*N2+(k-1)+1)];
    end
    data_f = fft(data_t);
    %multiply twiddle factor and stored in place
    for m = 1:N1
        data_f(m) = data_f(m)*exp(j*2*pi*(k-1)*(m-1)/N);
        data((m-1)*N2+(k-1)+1) = data_f(m);
    end
end
