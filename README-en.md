# My Mini CPU

This is a personal project of mine, showcasing a CPU developed on FPGA that can only print 'Hello world'.

[![Showcase Video](Docs/showcase.gif)](Docs/showcase.gif)

Magnified view of the output part:

![Output Amplified](Docs/image.png)

# Development Environment

- Arty S7 FPGA: https://digilent.com/reference/programmable-logic/arty-s7/start
- Vivado 2021.1

# CPU Features

I wanted to keep things as simple as possible, so this CPU supports only 4 instructions:

- ADD
- SUB
- IMM
- BNE

Each instruction operates directly on memory, with no register computation instructions.

The instruction set was inspired by:

[Simple ISA](https://courses.cs.washington.edu/courses/cse378/02sp/slides/simple-isa.html)

## Memory

The CPU provides 64 x 32-bit memory, about 0.2KB.

The code segment and data segment share 0.2KB of memory.

## Debug Output

The `[63]` memory address is used for UART debug output. Any data placed here will be output by the UART to the serial port on the development host. This allows us to print text.

# Assembler

I implemented an extremely simple Python assembler. Thanks to ChatGPT.

This assembler supports the 4 instructions above and can generate the final memory machine instruction code file.

![alt text](Docs/image-1.png)

# Implementation Details

## CPU Architecture

The CPU includes three main stages: IF, EX, WB. To simplify implementation as much as possible, I did not adopt a pipeline form, but rather the CPU executes one stage at a time.

Since instructions access memory directly, it is necessary to consider the delay during the memory read and write process. For this reason, the IF stage is divided into 4 sub-stages:
- IF0: Instruction reading
- IF1 - 4: Operand a, b, c reading

Since each memory read will have a delay, each sub-stage of the IF stage will wait for 5 clock cycles.

This is indeed not a very good implementation, but it is enough to complete this demo. I just hope to make things as simple as possible.

## Print Output

The URAT module will try to read from `[63]` memory, and if it is not 0, it will be considered as debug output. It will first clear this memory, then output the result to the serial port.

However, the output frequency of the URAT module is not consistent with the main CPU's running frequency, so the following technique is needed to implement the output of one character:

```assembly
    IMM 62 0
    IMM 63 72
    BNE 2 63 62
