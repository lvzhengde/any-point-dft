# Algorithm and Verilog HDL Implementation of Any-Point DFT/FFT

#### Introduction
This project describes the algorithm and Verilog HDL implementation for hardware-based any-point DFT. <br>
It uses an efficient and concise architecture to implement DFT of any length, including non-2^n-point DFT and 2^n-point FFT, with results perfectly matching theoretical values.<br>

#### Features
The project uses Matlab to describe any-point DFT algorithms in detail, and takes the LTE uplink SC-FDMA DFT (LTE DFT) as an example, covering everything from algorithm description to Verilog RTL implementation. Key features include:<br>
1.  Provides abundant Matlab source files for algorithm description, giving users full freedom to experiment with various algorithms, generate Matlab models, and produce stimulus and reference data for C-Model and Verilog RTL.
2.  Offers both floating-point and fixed-point C-Models for LTE DFT, so each Verilog RTL module has a corresponding C model, making it easy to verify design correctness and accelerate development.
3.  Uses a unified architecture to compute any-point DFT, including a pre-processing unit, a radix-2^2 FFT processor, and a post-processing unit.
4.  The pre-processing unit is essentially a sample rate conversion circuit. Its core polyphase filter can be implemented with about 6 taps, plus a linear interpolator. The main computational resources required are about 10 complex multipliers.
5.  The FFT processor uses a radix-2^2 algorithm and pipelined design, supporting standard 2^n-point FFTs, including 4, 8, 16, 32, 64, 128, 256, 512, 1024, and 2048 points.
6.  The post-processing unit mainly performs frequency domain compensation, almost perfectly restoring the frequency domain data distorted by the sample rate conversion circuit. Its mechanism is similar to frequency domain equalization in OFDM communication, with a simple structure and low computational resource usage.

#### Usage Instructions
The main directory structure of the project is as follows:
```
any_point_dft
├── algorithm
│   ├── doc
│   └── matlab
│       ├── cooley_tukey
│       ├── reference
|
├── lte_dft
│   ├── c_model
│   │   ├── fft_r22
│   │   ├── lte_dft
│   │   └── reference
│   ├── doc
│   ├── hdl
│   │   ├── rtl
│   │   │   ├── fft
│   │   │   ├── header
│   │   │   ├── postproc
│   │   │   ├── preproc
│   │   │   └── top
│   │   ├── sim
│   │   │   ├── dft
│   │   │   └── fft
│   │   └── tb
│   │       ├── dft
│   │       └── fft
│   └── matlab
```

The `algorithm` directory contains Matlab code for exploring and testing various hardware-implementable any-point DFT algorithms, helping to select the optimal scheme. The `lte_dft` directory implements the LTE uplink SC-FDMA DFT using the methods described in this project, from Matlab algorithms and C-models to Verilog RTL.<br>
If you are only interested in the algorithm for any-point DFT, focus on the following three files in `algorithm/matlab`: `preproc_fft_postproc.m`, `sample_rate_conv.m`, and `dft_main_lut.m`.<br>
If you are interested in both the algorithm and Verilog RTL implementation, study the contents under `lte_dft`. This includes detailed descriptions of filter design, radix-2^2 FFT processor design, floating/fixed-point conversion, and synthesizable Verilog HDL models.<br>
If you are only interested in 2^n-point FFT, the project includes a complete radix-2^2 pipelined FFT processor design, which can be extracted from the `lte_dft` directory.<br>
For more details, refer to the Word document "Overview-AnyPointDFT.docx" in the project root directory.<br>

#### About the RTL Model
This open-source project mainly focuses on algorithm exploration and feasibility. All derived models, such as RTL models, are considered correct and feasible as long as their results match the Matlab algorithm model.<br>
The RTL model is designed with reference to the fixed-point C-Model and may have minor differences. Its results are mainly compared with the Matlab algorithm model, and no strict bit-true comparison with the fixed-point C-Model has been performed. If you need a bit-accurate/cycle-accurate C model corresponding to the RTL model, please develop it yourself.<br>
After RTL model design, only basic functional/performance tests were performed. If you wish to use it in your own product development, please modify the design and conduct detailed testing to meet specific requirements.<br>
All development was done in a Windows environment: Matlab for algorithm models, VC for C models, and ModelSim for RTL simulation. If you need to port the project to Linux or use Python for algorithm description, please modify it yourself.<br>

#### Disclaimer

This design is free to use, and the author does not charge any fees.<br>
The author makes no guarantees about the results and assumes no legal responsibility.<br>
Users must acknowledge and agree to the above statement; if you do not agree, do not use it.<br>

#### Follow the Developer's WeChat Official Account
To learn about the latest project updates and join technical discussions, search for the WeChat official account "时光之箭" or scan the QR code below.<br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")
