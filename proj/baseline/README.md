
# Baseline codes

<p align="justify"> The baseline TFLite kernels were taken directly from the TFLite source, post which they have been instrumented to obtain the cycle counts of specific parts of the code. To do the same performance library is to be included in the C code. The CPU for the baseline is perf+cfu which has the provision of performance counters and the configuration of the same is available in the soc directory of the root. The synthesised design and all the Vivado reports are avaible in the build sub-directory of soc directory. The software has been unrolled to reduce the branch overheads, as well as gain from better spatiality of cache and kernel for the same is also available at: </p>

[Source TFLite Codes](./src/tensorflow)

<p align="justify"> The CPU configuration could be modified in the soc directory of root by following the below instructions available from the documentation: </p>

[Changing the CPU core](https://github.com/google/CFU-Playground/blob/main/soc/vexriscv/README.md)

<p align="justify">  The TFLite kernels are to be renamed as conv.h for execution. Firstly to load bitstream onto the Nexys4 board the below command is to  be used: </p> 

```
make prog PLATFORM=digilent_nexys4ddr EXTRA_LITEX_ARGS="--cpu-variant=perf+cfu"
```
Post this, to perform the inference, the following command is used to test with 7, 2, 1 as inputs:
```
make load PLATFORM=digilent_nexys4ddr
```

