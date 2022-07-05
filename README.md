# Conv2D_CFU

### Conv2D acceleration using CFU Playground framework, Mini-Project, Jan - May 2022

This repository holds code/experiments for the project Conv2D Acceleration using the framework CFU Playground. This is a forked repository of [CFU-Playground](https://github.com/google/CFU-Playground). 

#### Brief Description

<p align = "justify"> 
The convolution operation forms a major chunk of cycles spent in the case of Deep Neural Networks, and the acceleration of same could reduce the inference time. There exists 
several aspects of parallelism in the case of a Convolution which are to be coupled with better dataflow to gain from the benefits of memory re-use. There exists several 
frameworks to accelerate the convolution operation, but most of them end up being designed in isolation, or tend to accelerate the whole network on hardware
where the CPU core merely places the roll initial data-transfer. The CFU playground enables the development of accelerator in an integrated SoC environment solving
the storage and network bottlenecks that might arise when designed in isolation, while at the same time significant operations are performed on the VexRiscV core. 
The accelerator called the CFU (Custom FUnction Units) are invoked from the TFlite kernels using macros, and since a given Kernel could be re-used for 
multiple Networks, this offers more flexibility in terms of hardware. </p>

<p align = "justify"> A software baseline for an MNIST Neural Network was developed using the TFLite model and the same was profiled to identify the bottlenecks. It was further
analysed to identify aspects for parallelism as well as the possibilities of input data re-use. Post this the hardware accelerator was developed on the inferences drawn and same was optimised 
iteratively including aspects like changing the cache structure, degree of data re-use, amount of parallelism, till significant peformance was obtained. The accelerator was placed and 
rounted on a Nexys4 Artix-7 FPGA, and was succesfully tested. </p>

#### Getting Started and Software Baseline

<p align = "justify"> Few examples from source were implemented using Renode Simulation and these could help to get started with the framework. The files are available at (./proj/example_renode). However, as renode is not cycle 
accurate, in practise, either Verilator is to be used or an actual FPGA. The software baseline was implemented on a sufficiently Deep MNIST Neural Network is made available at (./proj/baseline). The procedure for execution of code is provided in the sub-repository. 

#### CFU Hardware Accelerator 

<p align = "justify"> The code for the Hardware accelerator is available as (./proj/accel). The detailed description along with the instructions 
to modify the core are presented. Further a short detail of the accelerator architecture could also be found. </p>



