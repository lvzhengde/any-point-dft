function y = dft_freq_fit(a, x)

%get compensation factor at first
global amp_comp_factor;
global data_len;
lut_2xlen = (length(amp_comp_factor)-1)*2;
delta_index = lut_2xlen / data_len;

%convert x into corresponding frequency index [1:length(amp_comp_factor)];
freq_index = floor(x * delta_index) + 1;

y = a * amp_comp_factor(freq_index);

