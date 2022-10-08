%%matlab program to generate compensation factor for Any-Point DFTs

clear all;
close all;
clc;

mkdir('./lut');

FIR_COEF          = './filter/fir_coef.dat';
SCALE_FILE_PREFIX = './lut/scale_lut';

tic
GEN_FIR_COEF = 1;

os= 64; 
polyphase= 6;
%get filter coefficients
fid_fir_coef = fopen(FIR_COEF, 'r');
fir_coef=fscanf(fid_fir_coef,'%g',inf);
fclose(fid_fir_coef);

%generate compensation factor
for len_index = 1: 1536
    symbol_f = [];
    symbol_f_any = [];
    scale_factor_in = [];
    
    data_len = len_index;
    ldn = ceil(log2(data_len));
    if(data_len == 2^ldn || data_len == 3*2^(ldn-2))
        continue;
    elseif(data_len < 3*2^(ldn-2))
        fft_len = 2^ldn;
    else
        fft_len = 3*2^(ldn-1);
    end

    SCALE_FILE = [SCALE_FILE_PREFIX, int2str(data_len), '.dat'];

    %%generate lut 
    symbol_f = ones(1, data_len);
    symbol_t_any=ifft(symbol_f); %create time domain data           
    symbol_f_any = preproc_fft_postproc(data_len, fft_len, symbol_t_any, polyphase, os, fir_coef);
    scale_factor = symbol_f./symbol_f_any;
    %%dump spectrum scale factor to file
    fid_scale_out = fopen(SCALE_FILE, 'wt');
    for k = 1:length(scale_factor)
        fprintf(fid_scale_out, '%16.13f\n', real(scale_factor(k)));
        fprintf(fid_scale_out, '%16.13f\n', imag(scale_factor(k)));
    end
    fclose(fid_scale_out);

end %%end non-2^n/3*2^n point loop

toc
