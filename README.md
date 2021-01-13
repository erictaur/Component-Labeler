# Component-Labeler
A hardware implementation of component labeling
Implementation Language: Verilog

## Used Software and Toolchains:
**Cadence**:
+ NCverilog
+ Innovus

**Synopsys**:
+ Design Compiler

## File/Folder Description:

`CLE.v`
+ Design source file.

`testbed.v`
+ Testbench for CLE.

`rom_128x8/` 
+ ROM related files for different binary image patterns.

`sram_1024x8/`
+ SRAM related files for different golden label data.
+ Do not use sram_1024x8.v in your design.

`.synopsys_dc.setup`
+ Configuration file for DC.

`CLE_DC.sdc`
+ Constraint file for synthesis.

`CLE_APR.sdc` 
+ Constraint file for APR.

`sram_for_design/`
+ SRAM related files. You can use these memories in your design.

Contain 3 types of SRAM:
1. sram_256x8
2. sram_512x8
3. sram_4096x8

## Introduction
In this final project, we are asked to design a Component Labeling Engine(CLE), which can detect object segmentation from the binary image, and give the same ID number to the same object.

![](https://i.imgur.com/i9Aukvz.png)

The Design Hierarchy is as shown.
![](https://i.imgur.com/oZf71jZ.png)

The input image is a 32x32 binary image as shown in the figure below. For the binary signal, 0 represents the background, and 1 represents the object for each pixel. You have to check if those pixels with value 1 are connected or not. The connected pixels represent to the same object. Those pixels are given with the same label ID from the same object. The number of label ID can be created arbitraily.

![](https://i.imgur.com/R2krpL3.png)

The image is already stored in a 128x8 ROM. The storing order is shown below. For example, if the address value is “0”, the corresponding 8-bit binary data represents the pixels [X=00, Y=00-07] in Fig.2. The MSB is related to [X=00, Y=00], and the LSB is related to [X=00, Y=07]. The number of times to read data from ROM is not constrained, and the signal CEN from ROM is always set to 0.

![](https://i.imgur.com/ILGNafg.png)

First, CLE has to find the pixel equal to 1 in the binary image, which means the object position. Then, it has to identify whether the pixel is connected to other pixels in a 3x3 block. The figure below shows the 8 connecting situations in a 3x3 block. If the pixels are connected, they are seen as the same object. Otherwise, the pixels which are not connected are seen as different object.

![](https://i.imgur.com/HCfr0kN.png)

