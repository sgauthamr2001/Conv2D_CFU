# Conv2D_CFU

### Conv2D acceleration using CFU Playground framework, Mini-Project, Jan - May 2022

<p align = "justify">  This repository holds code/experiments for the project Conv2D Acceleration using the framework CFU Playground. This is a forked repository of: </p>

[CFU-Playground](https://github.com/google/CFU-Playground)

#### Brief Description

<p align = "justify"> 
The convolution operation forms a major chunk of cycles spent in the case of Deep Neural Networks, and the acceleration of same could reduce the inference time. There exists 
several aspects of parallelism in the case of a Convolution which are to be coupled with better dataflow to gain from the benefits of memory re-use. There exists several 
frameworks to accelerate the convolution operation, but most of them end up being designed in isolation, or tend to accelerate the whole network on hardware
where the CPU core merely places the roll initial data-transfer. The CFU playground enables the development of accelerator in an integrated SoC environment solving
the storage and network bottlenecks that might arise when designed in isolation, while at the same time significant operations are performed on the VexRiscV core. 
The accelerator called the CFU (Custom Function Units) are invoked from the TFlite kernels using macros, and since a given Kernel could be re-used for 
multiple Networks, this offers more flexibility in terms of hardware. </p>

#### Setting up the environment 

<p align = "justify"> The documentation of the framework provides clear guidelines to setup the environment. Most of the dependencies are open-source. Only proprietary toolchain that would be needed is Xilinx Vivado. The following link guides the user on building the environment: </p>

[Setup Guide](https://cfu-playground.readthedocs.io/en/latest/setup-guide.html)

#### Getting Started and Software Baseline

<p align = "justify"> Few examples from source were implemented using Renode Simulation and these could help to get started with the framework. The files are available at: </p>

[Renode Examples](./proj/example_renode)

<p align = "justify"> However, as renode is not cycle 
accurate, in practise, either Verilator is to be used or an actual FPGA.  A software baseline for an MNIST Neural Network was developed using the TFLite model and the same was profiled to identify the bottlenecks. It was further
analysed to identify aspects for parallelism as well as the possibilities of input data re-use. The code is made available at: </p>

[Software Baseline](./proj/baseline) 

#### CFU Hardware Accelerator 

<p align = "justify"> The hardware accelerator was developed on the inferences drawn and same was optimised 
iteratively including aspects like changing the cache structure, degree of data re-use, amount of parallelism, till significant peformance was obtained. The accelerator was placed and 
rounted on a Nexys4 Artix-7 FPGA, and was succesfully tested. The code for the Hardware accelerator is available at: 

[Accelerator](./proj/accel) </p>

#### Results and Conlusions 
- <p align = "justify"> The framework CFU-Playground was reviewed in contrast to other existing frameworks, and particularly, its advantages like
  Integrated SoC environment, significant usage of the CPU core apart from the initial data transfer etc., have been exploited in
  this work. </p>
- <p align = "justify"> The Conv2D operation for a 3x3 case in an MNIST Neural Network was analysed and the Software Baseline was set-up in order
  to check for the bottlenecks. The software baseline for the given network took 335 M cycles for execution on a VexRiscV core
  placed, routed on a Nexys4 Artix-7 FPGA. The Conv2D operations consumed 334 M cycles of the total cycle count, and within 
  the Conv2D operation the MAC operations were the bottleneck being executed for 310 M cycles. The code was unrolled to
  reduce the loop overheads and gain from the spaciality of cache, which enhanced the cycle count to 220 M cycles. </p>
- <p align = "justify"> Using methods for parallelism like SIMD accumulation along input depth, parallel computation of independent strides and input
  data re-use between strides as well as multiple output channels, an accelerator was built. The integrated core when synthesised
  had a critical path of 9.446 ns in comparision to 8.785 ns for the core, indicating a minimal increase owing to the Integrated SoC
  environment. The inference took 15 M cycles on this integrated core. </p> 
- <p align = "justify"> The cache of core was slightly modified to lower number of bytes per line and on synthesis the the critical path was enhanced to
  9.338 ns. The network took 13 M cycles to execute on this integrated core.
- <p align = "justify"> The overall speed-up obtained was 26x for the base network and when tested for kernel re-use on a larger network the speed-up
  obtained was 33x. This was using the assumption that the baseline and the integrated accelerator were running at same clock
  since the difference in critical paths is minimal. Thus, the framework provides a better environment for the development of
  accelerators and the same was used to achieve the acceleration of 3x3 Conv2D kernels in case of a MNIST Neural Network, with
  a significant reduction in cycles. </p>


#### References 

- [CFU Playground: Framework for Tiny Machine Learning (tinyML) Acceleration on FPGAs, Prakash et al.](https://arxiv.org/abs/2201.01863)
- [hls4ml: An Open-Source Codesign Workflow to Empower Scientific Low-Power Machine Learning Devices, Fahim et al.](https://arxiv.org/abs/2103.05579)
- [SAMO: Optimised Mapping of Convolutional Neural Networks to Streaming Architectures, Alexander et al.](https://arxiv.org/pdf/2112.00170.pdf)
- [AutoDNNchip: An Automated DNN Chip Predictor and Builder for Both FPGAs and ASICs, Xu et al.](https://arxiv.org/abs/2001.03535)
- [Gemmini: Enabling Systematic Deep-Learning Architecture Evaluation via Full-Stack Integration, Genc et al.](https://arxiv.org/abs/1911.09925)
- [MEM-OPT: A Scheduling and Data Re-Use System to Optimize On-Chip Memory Usage for CNNs, Dinelli et al.](https://ieeexplore.ieee.org/document/9163269)
- [CARLA: A Convolution Accelerator with a Reconfigurable and Low-Energy Architecture, Mehdi et al.](https://arxiv.org/ftp/arxiv/papers/2010/2010.00627.pdf)





