%generate compensation factors
clear all
close all
clc

SCALE_FILE_PREFIX = './lut/scale_lut';
COMP_FACTOR_FILE  ='./lut/comp_factor.dat';

lte_dft_len = [12, 24, 36, 48, 60, 72, 96, 108, 120, 144, 180, 192, 216, 240, ...
  288, 300, 324, 360, 384, 432, 480, 540, 576, 600, 648, 720, 768, 864, 900, ...
  960, 972, 1080, 1152, 1200, 1296, 1536];

fid_comp = fopen(COMP_FACTOR_FILE, 'wt+');
for len_index = 1: length(lte_dft_len)
    scale_r = [];
    scale_i = [];
    data_len = lte_dft_len(len_index);
    SCALE_FILE = [SCALE_FILE_PREFIX, int2str(data_len), '.dat'];
    
    fid_scale_in = fopen(SCALE_FILE,'r');
    IN=fscanf(fid_scale_in,'%g',inf);
    fclose(fid_scale_in);
    for k=1:data_len
        scale_r(k) = IN(2*k-1);
        scale_i(k) = IN(2*k);
    end
    

	for k=1:floor(data_len/2)+1  
     fprintf(fid_comp, '%16.13f ,       %16.13f\n', scale_r(k), scale_i(k));
	end
end

fclose(fid_comp);
