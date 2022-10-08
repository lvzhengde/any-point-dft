%%matlab program to do Any-Point DFT
%%frequency compensation through curve fit

PRE_RUN = 1;
if PRE_RUN == 1
    run('./filter_design');    %design FIR filter for sample rate conversion
    run('./make_comp_lut');    %generate frequency compensation LUT
    run('./comp_factor_fit');  %curve fit for frequency compensation factor
end

clear all;
close all;
clc;

mkdir('./data');
mkdir('./data/input');
mkdir('./data/output');

FIR_COEF          = './filter/fir_coef.dat';
AMP_RESP          = './fit/amp_resp.dat';
COMP_COEF         = './fit/comp_coef.dat';

SOURCE_FILE       = './data/input/dft_gen';
MAT_RESULT_FILE   = './data/output/dft_sink_mat';

SCALE_FILE_PREFIX = './lut/scale_lut';

tic

os= 64; 
polyphase= 6;

fid_fir_coef = fopen(FIR_COEF, 'r');
fir_coef=fscanf(fid_fir_coef,'%g',inf);
fclose(fid_fir_coef);

global amp_comp_factor;
global data_len;
global delta_index;

%read amplitude response from file
fid_amp_resp = fopen(AMP_RESP, 'r');
amp_comp_factor = fscanf(fid_amp_resp, '%g', inf);
fclose(fid_amp_resp);

%read coefficients of curve fit for frequency compensation
fid_comp_coef = fopen(COMP_COEF, 'r');
comp_coef = fscanf(fid_comp_coef, '%g %g %g', [3 inf]);
fclose(fid_comp_coef);

%transpose
comp_coef = comp_coef';

%for SC-FDMA of LTE, the DFT length 
% lte_dft_len = [12, 24, 36, 48, 60, 72, 96, 108, 120, 144, 180, 192, 216, 240, ...
%   288, 300, 324, 360, 384, 432, 480, 540, 576, 600, 648, 720, 768, 864, 900, ...
%   960, 972, 1080, 1152, 1200, 1296, 1536];

LOOP_COUNT = 1;
for lp_cnt = 1:LOOP_COUNT
    symbol_f = [];
    symbol_f_any = [];

    scale_factor_in = [];
    scale_r = [];
    scale_i = [];
    
    m = 1;

    for len_index = 1: 1536
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
        
        %%do any point FFT and generate related results
        M=16;
        data_f=floor(M*rand(1,data_len));
        symbol_f = qammod(data_f,M);
%         symbol_f = (randn(1, data_len)+j*randn(1,data_len)) * sqrt(data_len);
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

        %generate frequency compensation factor by curve fit
        fit_len = floor(data_len/2);
        xdata = [0:fit_len];
%         [p, a, delta_index] = comp_coef(data_len,:);
        p = comp_coef(data_len, 1);
        a = comp_coef(data_len, 2);
        delta_index = comp_coef(data_len, 3);
        scale_amp = amp_func(a, xdata);
        scale_ang = ang_func(p, xdata);
        %notes: transpose of complex matrix including conjugate operation
        %scale_factor_tmp = scale_amp .* exp(j*scale_ang)'; %this is wrong.
        scale_factor_tmp = scale_amp.* conj((exp(j*scale_ang))');
        
        for mm = 0:data_len-1
            if (mm <= fit_len)
              scale_factor_fit(mm+1) = scale_factor_tmp(mm+1);
            else
              scale_factor_fit(mm+1) = conj(scale_factor_tmp(data_len-mm+1));
            end
        end
        
        %decision of abnormal condition
        diff_scale_factor = abs((scale_factor_in - scale_factor_fit))./(abs(scale_factor_in)+eps);
        if max(abs(diff_scale_factor)) > 0.01
            disp('Error in curve fit for frequency compensation factor!');
            break;
        end

        symbol_f_any = symbol_f_any.*scale_factor_fit;
        
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
        max_angle(m) = max(abs(unwrap(angle(scale_factor_fit(1:floor(data_len/2))))));
        m = m + 1;
        
        %scatterplot(symbol_f_any);
        
    end %%end non-2^n point loop
    max_error(lp_cnt) = max(error);
    
    scatterplot(symbol_f_any);
           
end %end LOOP_COUNT
toc
%%end simulation
