//command file for dft simulation

//pre-processing verilog files
../../../hdl/rtl/preproc/cyc_recon.v
../../../hdl/rtl/preproc/fir_coef_lut.v  
../../../hdl/rtl/preproc/preproc.v    
../../../hdl/rtl/preproc/preproc_fifo.v    
../../../hdl/rtl/preproc/src.v      

//fft verilog files 
../../../hdl/rtl/fft/radix2_unit.v
../../../hdl/rtl/fft/radix4_unit4.v
../../../hdl/rtl/fft/r4u4_two_ram.v
../../../hdl/rtl/fft/r4u4_one_ram.v
../../../hdl/rtl/fft/r4u4_bf2_two.v
../../../hdl/rtl/fft/r4u4_bf2_one.v
../../../hdl/rtl/fft/r4u4_twid_mul.v
../../../hdl/rtl/fft/r4u4_rom.v
../../../hdl/rtl/fft/radix4_unit3.v
../../../hdl/rtl/fft/r4u3_twid_mul.v
../../../hdl/rtl/fft/r4u3_two_ram.v
../../../hdl/rtl/fft/r4u3_one_ram.v
../../../hdl/rtl/fft/r4u3_bf2_two.v
../../../hdl/rtl/fft/r4u3_bf2_one.v
../../../hdl/rtl/fft/r4u3_rom.v
../../../hdl/rtl/fft/radix4_unit2.v
../../../hdl/rtl/fft/r4u2_bf2_two.v
../../../hdl/rtl/fft/r4u2_bf2_one.v
../../../hdl/rtl/fft/r4u2_twid_mul.v
../../../hdl/rtl/fft/r4u2_one_ram.v
../../../hdl/rtl/fft/r4u2_rom.v
../../../hdl/rtl/fft/radix4_unit1.v
../../../hdl/rtl/fft/r4u1_bf2_one.v
../../../hdl/rtl/fft/r4u1_bf2_two.v
../../../hdl/rtl/fft/r4u1_twid_mul.v
../../../hdl/rtl/fft/r4u1_rom.v
../../../hdl/rtl/fft/radix4_unit0.v
../../../hdl/rtl/fft/r4u0_bf2_one.v
../../../hdl/rtl/fft/r4u0_bf2_two.v
../../../hdl/rtl/fft/r4u0_twid_mul.v
../../../hdl/rtl/fft/bfp2fixed.v
../../../hdl/rtl/fft/fixed2bfp.v
../../../hdl/rtl/fft/bit_rev_ram.v
../../../hdl/rtl/fft/bit_reverse.v
../../../hdl/rtl/fft/fft.v

//post-processing verilog files
../../../hdl/rtl/postproc/freq_comp_rom.v
../../../hdl/rtl/postproc/postproc.v  

//top module
../../../hdl/rtl/top/dft.v     
../../../hdl/rtl/top/dft_wrapper.v     

//testbench files
../../../hdl/tb/dft/stimuli.v
../../../hdl/tb/dft/monitor.v
../../../hdl/tb/dft/harness.v
../../../hdl/tb/dft/testbench.v

+incdir+../../../hdl/rtl/header
