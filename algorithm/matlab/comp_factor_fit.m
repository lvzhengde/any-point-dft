clc;
close all;
clear all;

tic

mkdir('./fit');
SCALE_FILE_PREFIX = './lut/scale_lut';
FIR_COEF          = './filter/fir_coef.dat';
AMP_RESP          = './fit/amp_resp.dat';
COMP_COEF         = './fit/comp_coef.dat';


dft_len = [];
for len_index = 1: 1536
    ldn = ceil(log2(len_index));
    if(len_index == 2^ldn || len_index == 3*2^(ldn-2))
        continue;
    else
        dft_len = [dft_len, len_index];
    end
end

%++
%calculate frequence compensation factor in theory
%--
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

global amp_comp_factor;
fine_comp_factor = 20./abs(freq_resp);
amp_comp_factor = fine_comp_factor(1:2:end);

fid_amp_resp = fopen(AMP_RESP, 'wt');
fprintf(fid_amp_resp, '%16.8f\n', amp_comp_factor);
fclose(fid_amp_resp);

%++
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--

 for m = 1:length(dft_len)
  global   data_len;
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
  xdata = [0:fit_len];
  ydata_ang = unwrap(angle(scale_factor(1:fit_len+1)));
  x0  = -0.01;
  options = optimset('MaxFunEvals',100000*2, 'MaxIter', 100000*2);
  [p, s] = lsqcurvefit(@ang_func, x0, xdata, ydata_ang,[],[],options);
  p_angle(m,:) = p;
  s_ang(m) = s;
  y_ang = ang_func(p, xdata);

  ang_diff = abs(y_ang-ydata_ang)./(abs(ydata_ang)+eps);
  ang_max_diff(m) = max(ang_diff);
  
  %amplitude curve fit
  global delta_index;
  delta_index = (length(amp_comp_factor)-1)*2 / data_len;
  
  xdata = [0:fit_len];
  ydata = abs(scale_factor(1:fit_len+1));
  x0  = 1.0;
  options = optimset('MaxFunEvals',100000*2, 'MaxIter', 100000*2);

  [a, res] = lsqcurvefit(@amp_func, x0, xdata, ydata,[],[],options);  
  a_amp(m,:) = a;
  res_amp(m) = res;
  y=amp_func(a,xdata);
  amp_diff = abs(y-ydata)./(abs(ydata)+eps);
  amp_max_diff(m) = max(amp_diff);
  
  %delta increment factor of frequency index
  comp_coef(m,:) = [p, a, delta_index];
  
  %figure; plot(diff);
  
  disp(['iteration for data_len = ', int2str(data_len), '  completed!']);
end

%dump compensation factor, take DFT length as index, redundant data
%produced.
fid_comp_coef = fopen(COMP_COEF, 'wt');

dump_comp_coef = zeros(1536,3);
for n = 1:length(dft_len)
    dump_comp_coef(dft_len(n),:) = comp_coef(n,:);
end

for n = 1:1536
  fprintf(fid_comp_coef, '%16.8f   %16.8f   %16.8f\n', dump_comp_coef(n,1), dump_comp_coef(n,2), dump_comp_coef(n,3));
end
fclose(fid_comp_coef);

toc