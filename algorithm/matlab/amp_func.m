function y = amp_func(a, x)

%get compensation factor at first
global amp_comp_factor;
global data_len;
global delta_index;

%convert x into corresponding frequency index [1:length(amp_comp_factor)];
freq_index = floor(x * delta_index) + 1;

y = a * amp_comp_factor(freq_index);

