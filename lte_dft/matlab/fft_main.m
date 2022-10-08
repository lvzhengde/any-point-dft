%%matlab program to do LTE DFT by using 2^n-point FFT
%%apply lut to complete frequency compensation

clear all
close all
clc

FIR_COEF = './lut/fir_coef.dat';
SCALE_FILE_PREFIX = './lut/scale_lut';

tic
GEN_FIR_COEF = 1;
polyphase_window = 3;
%%for polyphase = 3*2, ibf = 0.35, w = [1 1000], kaiser beta = 3.8 can get
%%good results, max_error = 0.0036
%%%% create the src's coef here 
os= 32; %128;
polyphase= 2*polyphase_window;
%transition band
ibf=0.350;
n=os*polyphase-1;
f = [0 (1.0-ibf)/os (1.0+ibf)/os 1];
m=[1 1 0 0];
w=[1 1000]; %[1 10000];
lutRx_2=os*remez(n,f,m,w);
    
%add window
ham = kaiser(os*polyphase,3.8);
lutRx_2 = lutRx_2 .* ham';
%dump fir coefficients to file
if GEN_FIR_COEF == 1
  fid_fir_coef = fopen(FIR_COEF, 'wt');
  fprintf(fid_fir_coef, '%16.8f\n', lutRx_2);
  fclose(fid_fir_coef);
end

%LTE DFT length and corresponding FFT length
lte_dft_len = [12, 24, 36, 48, 60, 72, 96, 108, 120, 144, 180, 192, 216, 240, ...
  288, 300, 324, 360, 384, 432, 480, 540, 576, 600, 648, 720, 768, 864, 900, ...
  960, 972, 1080, 1152, 1200, 1296, 1536];
lte_fft_len = [16, 32, 64, 64, 128, 128, 128, 256, 256, 256, 256, 256, 512, 512, ...
  512, 512, 512, 512, 512, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024,2048, 2048, ...
  2048, 2048, 2048, 2048, 2048, 2048, 2048];

%loop for calculating LTE DFT
GEN_LUT = 0;
LOOP_COUNT = 1;
for lp_cnt = 1:LOOP_COUNT
    symbol_f = [];
    symbol_f_any = [];
    scale_factor_in = [];
    scale_r = [];
    scale_i = [];
    m = 1;

    for len_index = 1: length(lte_dft_len)
        data_len = lte_dft_len(len_index);
        fft_len = lte_fft_len(len_index);
        SCALE_FILE = [SCALE_FILE_PREFIX, int2str(data_len), '.dat'];
        
        %%generate lut at first
        if GEN_LUT == 1
            symbol_f = ones(1, data_len);
            symbol_t_any=ifft(symbol_f); %create time domain data           
            symbol_f_any = fft_shift_clip(data_len, fft_len, symbol_t_any, polyphase, os, lutRx_2);
            scale_factor = symbol_f./symbol_f_any;
            %%dump spectrum scale factor to file
            fid_scale_out = fopen(SCALE_FILE, 'wt');
            for k = 1:length(scale_factor)
                fprintf(fid_scale_out, '%16.13f\n', real(scale_factor(k)));
                fprintf(fid_scale_out, '%16.13f\n', imag(scale_factor(k)));
            end
            fclose(fid_scale_out);
        end %end generate lut

        %%do any point FFT and generate related results
%         M=4;
%         data_f=floor(M*rand(1,data_len));
%         symbol_f = qammod(data_f,M);
        symbol_f = randn(1, data_len);
        symbol_t_any=ifft(symbol_f); %create time domain data           
        symbol_f_any = fft_shift_clip(data_len, fft_len, symbol_t_any, polyphase, os, lutRx_2);
        %frequency compensation
        fid_scale_in = fopen(SCALE_FILE,'r');
        IN=fscanf(fid_scale_in,'%g',inf);
        fclose(fid_scale_in);
        for k=1:data_len
            scale_r(k) = IN(2*k-1);
            scale_i(k) = IN(2*k);
        end
        scale_factor_in = scale_r + j*scale_i;
        symbol_f_any = symbol_f_any.*scale_factor_in;
        %compare
        power_f =symbol_f*symbol_f'/length(symbol_f);
        error(m)=max(abs(symbol_f_any-symbol_f))/sqrt(power_f);  
        m = m + 1;
    end %%end non-2^n point loop
    max_error(lp_cnt) = max(error);
end %end LOOP_COUNT
toc
%%end simulation

