# Hardware Accelerator

<p align="justify"> The accelerator was built to overcome the shortcomings of software baseline, in order to benefit from parallelsim, while at the same time re-using of data by a maintaining a small scratch-pad for activations 
and accumulator output buffers. The architecture has been presented below, corresponds to cfu.v file in terms of implementation. The corresponding TFLite kernel can be found in the 
tensorflow sub-directory of src directory. The temp_files contain the undocumented intermediate version of the CFU and the corresponding kernel. </p>

<img width="1384" alt="pe" src="https://user-images.githubusercontent.com/63749705/177574503-4f9ce802-2676-4495-aa7a-da82b9c0b36d.png">

To perform the inference of the accelerator, we generate the bitstream using: 

```
make prog PLATFORM=digilent_nexys4ddr EXTRA_LITEX_ARGS="--cpu-variant=perf+cfu"
```
<p align="justify">  Further, to run the inference, the following command is to be used: </p> 

```
make load PLATFORM=digilent_nexys4ddr
```
<p align="justify"> The CPU was slightly modified on cache to gain slight improvement in performance, and the cpu-variant of the modified version is "dbpl8+cfu". The Vivado synthesis reports are available at the build sub-directory of soc directory from root. </p> 
