# 任意点数DFT/FFT的算法和Verilog HDL实现

#### 介绍
硬件实现任意点数DFT的算法描述以及Verilog HDL实现。<br>
使用一套高效简洁的设备实现任意点数的DFT，包括非2^n点的DFT和2^n点的FFT，结果完美逼近理论值。

#### 特点
项目使用Matlab语言对任意点DFT算法进行了详细描述，并以LTE上行链路SC-FDMA所用到的DFT（LTE DFT）为例从描述算法一直进行到Verilog RTL实现，特点如下：<br>
1.  提供丰富的Matlab源文件用于算法描述，读者拥有充分的自由度试验各种算法，生成Matlab模型，给C-Model和Verilog RTL产生激励数据和用于比对的结果数据
2.  提供LTE DFT的浮点和定点C-Model，从而Verilog RTL实现的各个模块都有一一对应的C语言模型，方便验证设计的正确性并加速开发进程
3.  使用一套结构不变的装置计算任意点的DFT，包括前处理单元，使用radix-2^2算法的FFT处理器，以及后处理单元
4.  前处理单元本质上是一个采样率转换电路，其核心部分的多相滤波器采用6个左右的抽头便可实现，加上线性插值器，前处理单元所需要的主要运算资源大约是10个左右的复数乘法器
5.  FFT处理器采用radix-2^2算法，流水线式设计，可以计算通常的2^n点FFT，包括4，8，16，32，64，128，256，512，1024，2048点FFT。
6.  后处理单元主要实现频域补偿，几乎完美恢复经过采样率转换电路后变形的频域数据，其实现机制类似于OFDM通信中的频域均衡，结构简单且所占运算资源不多


#### 使用说明
项目的主要目录结构如下：
```
any_point_dft
├── algorithm
│   ├── doc
│   └── matlab
│       ├── cooley_tukey
│       ├── reference
|
├── lte_dft
│   ├── c_model
│   │   ├── fft_r22
│   │   ├── lte_dft
│   │   └── reference
│   ├── doc
│   ├── hdl
│   │   ├── rtl
│   │   │   ├── fft
│   │   │   ├── header
│   │   │   ├── postproc
│   │   │   ├── preproc
│   │   │   └── top
│   │   ├── sim
│   │   │   ├── dft
│   │   │   └── fft
│   │   └── tb
│   │       ├── dft
│   │       └── fft
│   └── matlab
```

algorithm目录下的内容使用Matlab语言，探索试验可用硬件实现任意点DFT的各种算法，挑选出最优的方案；lte_dft目录则是使用本项目所描述的方法，从Matlab算法，C-model一直到Verilog RTL，实现LTE上行链路SC-FDMA所用到的DFT。<br>
如果只是对任意点数DFT的算法感兴趣，建议重点研读algorithm/matlab目录下的preproc_fft_postproc.m，sample_rate_conv.m，以及dft_main_lut.m这三个文件即可。<br>
如果对算法和Verilog RTL实现均有兴趣，则需要研读lte_dft目录下的内容。里面对滤波器设计，radix-2^2 FFT处理器设计，浮点定点转换等算法方面的内容都有详尽描述，并设计出了可综合的Verilog HDL模型。<br>
如果只对2^n点的FFT感兴趣，项目包含了一个完整的radix-2^2 流水线式FFT处理器的设计，可以从lte_dft目录下剥离出来。<br>
更多的描述，可以参考项目根目录下的word文件"综述-AnyPointDFT.docx"。<br>

#### 关于RTL模型
本开源项目主要关注算法探索和其可实现性，所有的衍生模型如RTL模型只要它的结果和Matlab算法模型保持一致就认为是正确可行的。<br>
RTL模型是参考定点C-Model设计的，可能有一些细微差别，其结果主要是和Matlab算法模型比较，没有和定点C-Model做过严格的bit-true比较。如果读者需要和RTL模型对应的bit-accurate/cycle-accurate的C模型，请自行开发。<br>
RTL模型设计完成后，只是做了基本的功能/性能测试，如果读者希望在自己的产品研发中使用，请自行修改设计并做详细测试以满足相关的特定需求。<br>
所有的开发工作都是在Windows环境中完成的，算法模型用Matlab描述，C模型使用VC开发，RTL使用ModelSim仿真。如果读者需要将项目移植到Linux系统，使用Python描述算法等等，请自行修改。<br>


#### 免责声明

本设计可以自由使用，作者不索取任何费用。 <br>
作者对使用结果不做任何承诺也不承担其产生的任何法律责任。<br>
使用者须知晓并同意上述申明，如不同意则不要使用。<br>

#### 关注开发者公众号
如果需要了解项目最新状态和加入相关技术探讨，请打开微信搜索公众号"时光之箭"或者扫描以下二维码关注开发者公众号。<br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")

