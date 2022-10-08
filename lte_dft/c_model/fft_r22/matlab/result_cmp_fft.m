%compare FFT result from matlab with that of C-model 
clc
clear
close all;
SOURCE_FILE = '../data/input/fft_gen';
MAT_RESULT_FILE =  '../data/output/fft_mat_comm';
% C_RESULT_FILE = '../data/output/fft_sink_pipe';
C_RESULT_FILE = '../data/output/fft_bfp';

ldn = 10;
datalen = 2^ldn;
%read data from source and do FFT in Matlab
file_name = [SOURCE_FILE, num2str(datalen), '.dat'];
fid = fopen(file_name,'r');
IN=fscanf(fid,'%g%g',[2, inf]);
fclose(fid);
x_r = IN(1,:);
x_i = IN(2,:);

%do FFT
X = x_r + j*x_i;
Y = fft(X, datalen);
%normalize power 
% sqrt_mean_power = mean(abs(Y));
% Y = Y/sqrt_mean_power;

% dump FFT data to file
file_name = [MAT_RESULT_FILE, num2str(datalen), '.dat']; 
fid = fopen(file_name, 'wt+');
for k = 1:datalen
  fprintf(fid, '%12.8f       %12.8f\n', real(Y(k)), imag(Y(k)));
end
fclose(fid);

% figure
% plot(Y, '.');

%read C-model fft result file
file_name = [C_RESULT_FILE, num2str(datalen), '.dat']; 
fid_fft = fopen(file_name,'r');
IN_fft=fscanf(fid_fft,'%g%g',[2, inf]);
fclose(fid_fft);
x_r_fft = IN_fft(1,:);
x_i_fft = IN_fft(2,:);

Z = x_r_fft + j * x_i_fft;
%normalize power
% sqrt_mean_power = mean(abs(Z));
% Z = Z/sqrt_mean_power;

% figure
% plot(Z, '.')

%compare the result from ifft and source
FFT_DIFF = abs(Y -Z);
f = 0:1:datalen-1;
figure
plot(f, 20*log10((FFT_DIFF+eps)/(mean(abs(Y))+eps)))

SQNR = 20*log10(mean(FFT_DIFF)/mean(abs(Y)))

%%%% caculate the evm
% symbol_f_4096=Z;
% p=symbol_f_4096*symbol_f_4096'/length(symbol_f_4096);
% error_evm=(abs(real(symbol_f_4096))-1.0/sqrt(2))+j*(abs(imag(symbol_f_4096))-1.0/sqrt(2));
% 
% evm= sqrt(error_evm*error_evm'/length(symbol_f_4096))/sqrt(p)
% evm_db=20*log10(evm)



