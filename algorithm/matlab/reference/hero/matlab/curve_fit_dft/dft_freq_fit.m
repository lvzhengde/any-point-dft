function y = dft_freq_fit(a, x)

%get compensation factor at first
global amp_comp_factor;

%convert x into corresponding frequency index [1:length(amp_comp_factor)];
freq_index = floor(x * (length(amp_comp_factor)-1)/(length(x)-1)) + 1;

y = a * amp_comp_factor(freq_index);

