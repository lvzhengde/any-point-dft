clear all
close all
clc

SCALE_FILE1 = './lut/scale_lut324.dat';
SCALE_FILE2 = './lut/scale_lut1536.dat';

data_len1 = 324;
data_len2 = 1536;

tic

fid_scale_in = fopen(SCALE_FILE1,'r');
IN=fscanf(fid_scale_in,'%g',inf);
fclose(fid_scale_in);
for k=1:data_len1
    scale_r1(k) = IN(2*k-1);
    scale_i1(k) = IN(2*k);
end
scale_factor1 = scale_r1 + j*scale_i1;

fid_scale_in = fopen(SCALE_FILE2,'r');
IN=fscanf(fid_scale_in,'%g',inf);
fclose(fid_scale_in);
for k=1:data_len2
    scale_r2(k) = IN(2*k-1);
    scale_i2(k) = IN(2*k);
end
scale_factor2 = scale_r2 + j*scale_i2;
  
%curve fit
xdata = [0:768];
ydata = abs(scale_factor2(1:769));
x0 = [0.5569    0.0561    0.0030   -0.1163    0.8510   0.0539   0];

options = optimset('MaxFunEvals',100000, 'MaxIter', 100000);

[a, res] = lsqcurvefit(@freq_fit, x0, xdata, ydata,[],[],options);
  
toc