# MNIST Neural Network
The implementation of a int8 quantised custom MNIST model with following architecture: 
- Conv2D + ReLU, 3x3 Kernel, 12 Out_channels
- Conv2D + ReLU, 3x3 Kernel, 12 Out_channels
- MaxPool2D
- Flatten + FC Layer

Optimisations have been performed using template SIMD unit provided, following are cycle counts, 
on renode emulation (each Tick is 1024 cycles): 

- Without any optimisations:
    - Conv2D (1) - 3322 Ticks 
    - Conv2D (2) - 10215 Ticks 
    - Total - 14M cycles 
- Common Constants replaced:
    - Conv2D (1) - 2390 Ticks 
    - Conv2D (2) - 7411 Ticks 
    - Total - 10M cycles 
- After in_channel loop unrolled:   
    - Conv2D (1) - 1630 Ticks 
    - Conv2D (2) - 5575 Ticks 
    - Total - 7677K cycles 
- After CFU SIMD Hardware (Only MAC for Conv2D (1)):
    - Conv2D (1) - 1530 Ticks 
    - Conv2D (2) - 1602 Ticks 
    - Total - 3506K cycles
- After model specific constants replaced:
    - Conv2D (1) - 1477 Ticks 
    - Conv2D (2) - 1490 Ticks 
    - Total - 3337K cycles
    
Thus, there is a significant reduction in number of cycles. 
