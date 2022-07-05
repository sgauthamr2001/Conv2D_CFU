# Renode Examples 

<p align="justify"> The framework offers renode simulation which is typically faster than Verilator for the purpose of functional verification. The current repository has been implemented to test out the efficiency of renode in comparision to that of verilator. An MNIST Neural Network software stack was implemented in the common sub-repository of main repository. To test out the software stack, a set of examples for optimisation have been implemented in renode following the tutorial provided in the documentation. The tutorial is available as the following location : </p>

[Step-by-Step guide to build an ML accelerator](https://cfu-playground.readthedocs.io/en/latest/step-by-step.html)

<p align="justify">  The TFLite kernels found in the src repository could be modified to perform several different optimisations like unrolling, SIMD accumulation, constant replacement etc., and to run the inference using renode, following command could be used: </p> 

```
make renode
```
<p align="justify">  Further, to run the same inference using verilator, the following command is to be used: </p> 

```
make PLATFORM=sim load
```
<p align="justify"> Adding the following extra argument to both verilator or renode shall generate the waveform traces which could be visualised using open-source tools like gtkwave. </p> 

```
ENABLE_TRACE_ARG=--trace-fst
```
<p align="justify"> On comparing both the waveforms generated using verilator and renode, it could be inferred that renode does not simulate the junk data which is fed to the CFU between succesive calls, thus not only gives a reduced cycle count, but also leads to errors if this junk is not handled appropriately. </p>
