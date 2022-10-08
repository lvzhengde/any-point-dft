#fft.do command file
vlog -f comp.f -sv
vopt work.testbench +acc -o testbench0
vsim testbench0
