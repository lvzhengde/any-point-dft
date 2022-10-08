%%matlab program to do Any-Point DFT
%%apply lut to complete frequency compensation

clear all;
close all;
clc;

FIR_COEF          = './lut/fir_coef.dat';
SCALE_FILE_PREFIX = './lut/scale_lut';
SOURCE_FILE       = './data/input/dft_gen';
MAT_RESULT_FILE   = './data/output/dft_sink_mat';

tic
GEN_FIR_COEF = 1;

os= 64; %128;
polyphase= 6;
if GEN_FIR_COEF == 1
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
else
    fid_fir_coef = fopen(FIR_COEF, 'r');
    fir_coef=fscanf(fid_fir_coef,'%g',inf);
    fclose(fid_fir_coef);
end

%LTE DFT length and corresponding FFT length
% lte_dft_len = [12, 24, 36, 48, 60, 72, 96, 108, 120, 144, 180, 192, 216, 240, ...
%   288, 300, 324, 360, 384, 432, 480, 540, 576, 600, 648, 720, 768, 864, 900, ...
%   960, 972, 1080, 1152, 1200, 1296, 1536];
% lte_fft_len = [16, 32, 64, 64, 128, 128, 128, 256, 256, 256, 256, 256, 512, 512, ...
%   512, 512, 512, 512, 512, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024,2048, 2048, ...
%   2048, 2048, 2048, 2048, 2048, 2048, 2048];

%loop for calculating LTE DFT
GEN_LUT = 1;
LOOP_COUNT = 1;
for lp_cnt = 1:LOOP_COUNT
    symbol_f = [];
    symbol_f_any = [];
    scale_factor_in = [];
    scale_r = [];
    scale_i = [];
    m = 1;

    for len_index = 7: 1536
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
        
        %%generate lut at first
        if GEN_LUT == 1
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
        end %end generate lut

        %%do any point FFT and generate related results
%         M=4;
%         data_f=floor(M*rand(1,data_len));
%         symbol_f = qammod(data_f,M);
        symbol_f = (randn(1, data_len)+j*randn(1,data_len)) * sqrt(data_len);
        symbol_t_any=ifft(symbol_f); %create time domain data     
        %dump input data to dft
        file_name = [SOURCE_FILE, num2str(data_len), '.dat'];
        fid = fopen(file_name, 'wt+');
        for k=1:data_len  
          fprintf(fid, '%20.13f       %20.13f\n', real(symbol_t_any(k)), imag(symbol_t_any(k)));
        end
        fclose(fid);

        symbol_f_any = preproc_fft_postproc(data_len, fft_len, symbol_t_any, polyphase, os, fir_coef);
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
        %dump dft result to file
        file_name = [MAT_RESULT_FILE, num2str(data_len), '.dat']; 
        fid = fopen(file_name, 'wt+');
        for k = 1:data_len
          fprintf(fid, '%15.8f       %15.8f\n', real(symbol_f_any(k)), imag(symbol_f_any(k)));
        end
        fclose(fid);        
        
        %compare
        power_f  = symbol_f*symbol_f'/length(symbol_f);
        error(m) = max(abs(symbol_f_any-symbol_f))/sqrt(power_f); 
        mean_error(m) = mean(abs(symbol_f_any-symbol_f))/sqrt(power_f); 
        max_angle(m) = max(abs(unwrap(angle(scale_factor_in(1:floor(data_len/2))))));
        m = m + 1;
    end %%end non-2^n point loop
    max_error(lp_cnt) = max(error);
end %end LOOP_COUNT
toc
%%end simulation
