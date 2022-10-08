%compare FFT result from matlab with that of C-model 
clc
clear
close all;

SOURCE_FILE  =  '../data/output/fft_bfp';
DESTINE_FILE =  '../data/output/fft_sink_pipe';

ldn = 3;
datalen = 2^ldn;
%read data from source file
file_name = [SOURCE_FILE, num2str(datalen), '.dat'];
fid = fopen(file_name,'r');
IN=fscanf(fid,'%g%g',[2, inf]);
fclose(fid);
x_r = IN(1,:);
x_i = IN(2,:);

X = x_r + j*x_i;

% figure
% plot(X, '.')

%read data from destination file
file_name = [DESTINE_FILE, num2str(datalen), '.dat'];
fid_des = fopen(file_name,'r');
IN_DES=fscanf(fid_des,'%g%g',[2, inf]);
fclose(fid_des);
y_r = IN_DES(1,:);
y_i = IN_DES(2,:);

Z = y_r + j * y_i;
%normalize power
% sqrt_mean_power = mean(abs(Z));
% Z = Z/sqrt_mean_power;

%compare the result from ifft and source
FFT_DIFF = abs(X -Z);
f = 0:1:datalen-1;
figure
plot(f, 20*log10((FFT_DIFF+eps)./(mean(abs(Z))+eps)))

mean_snr = mean(20*log10((FFT_DIFF+eps)./(abs(Z)+eps)))

%%%% caculate the evm
% symbol_f_4096=Z;
% p=symbol_f_4096*symbol_f_4096'/length(symbol_f_4096);
% error_evm=(abs(real(symbol_f_4096))-1.0/sqrt(2))+j*(abs(imag(symbol_f_4096))-1.0/sqrt(2));
% 
% evm= sqrt(error_evm*error_evm'/length(symbol_f_4096))/sqrt(p)
% evm_db=20*log10(evm)



