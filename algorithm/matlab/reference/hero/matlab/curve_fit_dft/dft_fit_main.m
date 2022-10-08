clc;
close all;
clear all;

tic

SCALE_FILE_PREFIX = './lut/scale_lut';

dft_len = [12, 24, 36, 48, 60, 72, 96, 108, 120, 144, 180, 192, 216, 240, ...
  288, 300, 324, 360, 384, 432, 480, 540, 576, 600, 648, 720, 768, 864, 900, ...
  960, 972, 1080, 1152, 1200, 1296, 1536];

%++
%calculate frequence compensation factor in theory
%--
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
global amp_comp_factor;
fine_comp_factor = 20./abs(freq_resp);
amp_comp_factor = fine_comp_factor(1:8:end);

%++
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--

% m = 35;
 for m = 1:length(dft_len)
  data_len = dft_len(m);
  SCALE_FILE = [SCALE_FILE_PREFIX, int2str(data_len), '.dat'];
  
  fid_scale_in = fopen(SCALE_FILE,'r');
  IN=fscanf(fid_scale_in,'%g',inf);
  fclose(fid_scale_in);
  for k=1:data_len
      scale_r(k) = IN(2*k-1);
      scale_i(k) = IN(2*k);
  end
  scale_factor = scale_r + j*scale_i;
  
  fit_len = floor(data_len/2);
   
  %angle polyfit
% %   fit_len = floor(data_len/2);
% %   xdata = [0:fit_len];
% %   [p, s] = polyfit(xdata, unwrap(angle(scale_factor(1:fit_len+1))), 1);
% %   p_angle(m,:) = p;
% %   s_ang(m) = s;
  
  %amplitude curve fit
  xdata = [0:fit_len];
  ydata = abs(scale_factor(1:fit_len+1));
  %x0 = [abs(scale_factor(1))*0.75   0    0    0   abs(scale_factor(1))*0.15   0    0.55]; %optimized sinc coefficient 0.6202
  x0  = 1.0;
  options = optimset('MaxFunEvals',100000*2, 'MaxIter', 100000*2);

  [a, res] = lsqcurvefit(@dft_freq_fit, x0, xdata, ydata,[],[],options);  
  a_amp(m,:) = a;
  res_amp(m) = res;
  y=dft_freq_fit(a,xdata);
  diff = abs(y-ydata)./abs(ydata);
  max_diff(m) = max(diff);
  
  figure; plot(diff);
  
  disp(['iteration for data_len = ', int2str(data_len), '  completed!']);
 end

toc