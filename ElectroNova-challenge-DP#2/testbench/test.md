# ElectroNova DMA Verification Suite

## Overview
This folder contains the standalone verification environment for the `tqvp_dma` module, built using **Cocotb** and **Icarus Verilog**. 

Rather than relying purely on CPU integration tests, we developed a targeted, isolated testbench to strictly verify the **PPA Performance** and **FSM logic** of our optimized DMA.

## Verification Features
1. **Memory-Mapped Configuration:** The test simulates the CPU writing to the control registers (`src_addr`, `dst_addr`, `length`) before asserting the start pulse, verifying the IDLE-to-BUSY transition logic.
2. **Concurrent Memory Slave:** To test the maximum throughput of our 4-word FIFO pipeline, the testbench spawns a background `dummy_memory_slave` task. This task holds `m_ready` high and responds to `m_read` requests instantly, simulating a zero-wait-state memory.
3. **Master Bus Handshaking:** The Python assertions guarantee that the DMA strictly adheres to Master/Slave protocol, never asserting `m_valid` unless data is actively being streamed.

## How to Run
Ensure `cocotb` and `iverilog` are installed, then execute:
\`\`\`bash
make -f test_dma.mk
\`\`\`
gtkwave run command : gtkwave tqvp_dma.fst

## Results
The design successfully passes all assertions, proving the hardware state machine correctly transitions from IDLE -> CONFIGURE -> READ -> WRITE at a 25MHz clock speed without hanging or deadlocking.