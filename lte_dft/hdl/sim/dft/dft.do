#dft.do command file
vlog -f comp.f
vopt work.testbench +acc -o testbench0
vsim testbench0
