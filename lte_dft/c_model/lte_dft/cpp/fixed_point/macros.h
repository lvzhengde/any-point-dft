#ifndef __MACROS_H__
#define __MACROS_H__

//definitions for RAM and ROM
//#define    FIR_COEF_FILE  "F:/project/lte_dft/hdl/rtl/preproc/fir_lut.dat"
//
//#define    ROM_FILE_R4U1  "F:/project/lte_dft/hdl/rtl/fft/rom_file_r4u1.dat"       
//#define    ROM_FILE_R4U2  "F:/project/lte_dft/hdl/rtl/fft/rom_file_r4u2.dat"       
//#define    ROM_FILE_R4U3  "F:/project/lte_dft/hdl/rtl/fft/rom_file_r4u3.dat"       
//#define    ROM_FILE_R4U4  "F:/project/lte_dft/hdl/rtl/fft/rom_file_r4u4.dat"       
//
//#define    COMP_FILE      "F:/project/lte_dft/hdl/rtl/postproc/comp_file.dat"

#define    FIR_COEF_FILE  "../../../../hdl/rtl/preproc/fir_lut.dat"

//#define    ROM_FILE_R4U1  "../../../../hdl/rtl/fft/rom_file_r4u1.dat"       
//#define    ROM_FILE_R4U2  "../../../../hdl/rtl/fft/rom_file_r4u2.dat"       
//#define    ROM_FILE_R4U3  "../../../../hdl/rtl/fft/rom_file_r4u3.dat"       
//#define    ROM_FILE_R4U4  "../../../../hdl/rtl/fft/rom_file_r4u4.dat"       

#define    COMP_FILE      "../../../../hdl/rtl/postproc/comp_file.dat"

#define    TEST_FILE      "../../data/debug/fft_r4u4in972.dat"


//macro definitions for rtl
#define    FIR_CO_WIDTH          (14)
#define    L                     (32)    //upsampling times
#define    P                     (6)     //sub filter length

#define   BIT_REV                (true)

#define    FFT_IN_WIDTH          (16)
#define    FFT_IN_PTPOS          (12)

#define    FFT_OUT_WIDTH         (18)
#define    FFT_OUT_PTPOS         (8)

#define    COEF_WIDTH            (13)
#define    MAN_WIDTH             (13)
#define    EXP_WIDTH             (5)


#endif  //__MACROS_H__