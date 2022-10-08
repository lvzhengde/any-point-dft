`ifndef __MACROS_H__
`define __MACROS_H__

`timescale 1ns/100ps

`define    SIMULATION

//definitions for RAM and ROM
//`define    FIR_COEF_FILE  "F:/project/lte_dft/hdl/rtl/preproc/fir_lut.dat"

//`define    ROM_FILE_R4U1  "F:/project/lte_dft/hdl/rtl/fft/rom_file_r4u1.dat"       
//`define    ROM_FILE_R4U2  "F:/project/lte_dft/hdl/rtl/fft/rom_file_r4u2.dat"       
//`define    ROM_FILE_R4U3  "F:/project/lte_dft/hdl/rtl/fft/rom_file_r4u3.dat"       
//`define    ROM_FILE_R4U4  "F:/project/lte_dft/hdl/rtl/fft/rom_file_r4u4.dat"       

`define    FIR_COEF_FILE  "../../../hdl/rtl/preproc/fir_lut.dat"
`define    BIN_FIR_COEF_FILE  "../../../hdl/rtl/preproc/fir_lut.bin"

`define    ROM_FILE_R4U1      "../../../hdl/rtl/fft/rom_file_r4u1.dat"   
`define    ROM_FILE_R4U2      "../../../hdl/rtl/fft/rom_file_r4u2.dat"   
`define    ROM_FILE_R4U3      "../../../hdl/rtl/fft/rom_file_r4u3.dat"   
`define    ROM_FILE_R4U4      "../../../hdl/rtl/fft/rom_file_r4u4.dat"   
`define    BIN_ROM_FILE_R4U1  "../../../hdl/rtl/fft/rom_file_r4u1.bin"   
`define    BIN_ROM_FILE_R4U2  "../../../hdl/rtl/fft/rom_file_r4u2.bin"   
`define    BIN_ROM_FILE_R4U3  "../../../hdl/rtl/fft/rom_file_r4u3.bin"   
`define    BIN_ROM_FILE_R4U4  "../../../hdl/rtl/fft/rom_file_r4u4.bin"   

`define    COMP_FILE      "../../../hdl/rtl/postproc/comp_file.dat"
`define    BIN_COMP_FILE      "../../../hdl/rtl/postproc/comp_file.bin"

//macro definitions for rtl
`define    P_LEN                 (6)
`define    FIR_CO_WIDTH          (14)
`define    L_LDN                 (5)

`define    FFT_IN_WIDTH          (16)
`define    FFT_IN_PTPOS          (12)
`define    FFT_OUT_WIDTH         (18)
`define    FFT_OUT_PTPOS         (8)
`define    COEF_WIDTH            (13)
`define    MAN_WIDTH             (13)
`define    EXP_WIDTH             (5)

//macro definitions for tb
`define    FFT_TEST

`ifdef  FFT_TEST
  //`define    FFT_BIT_REV
  `define    FFT_MODE              (0)
  `define    GAP_LEN               (8)
  `define    INPUT_SYM_CYCLES      (2)
  `define    DUMP_FRAMES           (32)
  `define    TEST_LDN              (11)
  //`define    RAND_SEED             (20)
  `define    RAND_TEST

//`define    STIMULI_FILE    "F:/project/lte_dft/c_model/fft_r22/data/input/fft_gen16.dat"
//`define    DUMP_FILE       "F:/project/lte_dft/hdl/sim/fft/data_sink/fft_vlog16.dat"     
//`define    DUMP_VCD_FILE   "F:/project/lte_dft/hdl/sim/fft/data_sink/fft_vcd16.vcd" 

  `define    STIMULI_FILE    "../../../c_model/fft_r22/data/input/fft_gen"
  `define    DUMP_FILE       "../../../hdl/sim/fft/data_sink/fft_vlog"
  `define    DUMP_VCD_FILE   "../../../hdl/sim/fft/data_sink/fft_vcd.vcd"
  
  `define    TEST_FILE       "../../../hdl/sim/fft/temp/r4u2_bf1_vlog.dat"

`else    //for dft test
  `define    DFT_MODE              (0)      //0: DFT; 1: iDFT
  `define    TEST_DFT_LEN          (16)
  
  `define    INPUT_SYM_CYCLES      (2)
  `define    DUMP_FRAMES           (5)
  //`define    RAND_TEST

  `define    STIMULI_FILE    "../../../c_model/lte_dft/data/input/dft_gen"
  `define    DUMP_FILE       "../../../hdl/sim/dft/data_sink/dft_vlog"
  `define    DUMP_VCD_FILE   "../../../hdl/sim/dft/data_sink/dft_vcd.vcd"
  
  `define    TEST_FILE       "../../../hdl/sim/dft/temp/fft_r4u4in972_vlog.dat"  
`endif   //FFT_TEST

`endif  //__MACROS_H__
