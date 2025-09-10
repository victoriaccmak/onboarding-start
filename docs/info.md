<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is Victoria Mak's onboarding project for UWASIC.

This project is an SPI-controlled PWM peripheral. It contains a PWM peripheral module and an SPI peripheral module. The 
PWM module controls the output signals to be pulled high for a percentage of the time to control the average power 
delivered to a device. The output depends on values stored within registers which are controlled by an SPI Peripheral.

This project takes in three signals: COPI, nCS, and SCLK. COPI is delivered to the system as a bitstream of 16 bits, with
the first bit being Read/Write, the next seven bits controlling the address of the register, and the least significant eight
bits storing the actual data.

Through the SPI protocol, the SPI peripheral takes in the data from COPI and writes data to the corresponding register to 
control various settings of the PWM peripheral. This includes settings for enabling output ports, enabling PWM on the output
ports, and the PWM Duty Cycle (which is the average desired power).

## How to test

Attached to the project is test_project.py. To run these tests, navigate to the /test directory. Then, run:
  make -B
To see the waveform, run:
  gtkwave tb.vcd

## External hardware

Currently there are no external hardware.
