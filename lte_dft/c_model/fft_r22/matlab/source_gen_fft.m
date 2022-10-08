%fft source generate program
clc
close all
clear all
SOURCE_FILE = '../data/input/fft_gen';

ldn = 5;
%modulation in Tx side
map=[4.5+j*4.5  -4.5+j*4.5 -4.5-j*4.5 4.5-j*4.5];
datalen=2^ldn;
%dataint=randint(1,datalen,4);
for k = 1: datalen
%   dataint(k) = floor(4*rand);
  data(k) = randn + j*randn;
end
% data=map(dataint+1);
tr_data=ifft(data);
sqrt_mean_power = mean(abs(tr_data));
tr_data = tr_data/sqrt_mean_power;

%dump rand data to source file
file_name = [SOURCE_FILE, num2str(datalen), '.dat'];
fid = fopen(file_name, 'wt+');
for k=1:datalen  
 fprintf(fid, '%12.8f       %12.8f\n', real(tr_data(k)), imag(tr_data(k)));
end

fclose(fid);


