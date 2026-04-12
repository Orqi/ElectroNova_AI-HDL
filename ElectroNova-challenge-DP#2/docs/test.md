#  DMA Module Testing Guide

> ###  QUICK START: HOW TO RUN TESTS
> **1. Python/Cocotb Module Tests**
> ```bash
> cd ElectroNova_AI-HDL/test
> make -B
> ```
> 
> **2. Verilog Native Testbench**
> ```bash
> cd ElectroNova_AI-HDL/test
> iverilog -g2009 -o tb_dma.vvp tb_dma.v ../src/user_peripherals/tqvp_dma.v
> vvp tb_dma.vvp
> ```
> 
> **3. View Waveforms (Bonus)**
> ```bash
> gtkwave dma.vcd
> ```

---

## 🔍 Types of Tests Conducted

The DMA module (`tqvp_dma`) is validated using two distinct testing environments to ensure robust hardware behavior. Both test suites include an **FSM Watchdog** to automatically bypass a known RTL deadlock bug in the `ISSUE_WRITE` state.

### 1. Python/Cocotb Test Suite (`test_dma.py`)
This suite uses Python to act as a virtual RISC-V processor and memory bus, interacting with the Verilog DMA module.
* **Basic 1D Transfer (`test_dma_full`):** Validates standard linear memory copying (16 words) from a base source to a base destination.
* **2D Strided Transfer (`test_dma_2d`):** Tests the advanced AI-HDL 2D striding logic. It verifies that the DMA can jump to next rows (`src_stride`) after hitting the configured `row_size`.

### 2. Native Verilog Testbench (`tb_dma.v`)
This suite simulates pure hardware-level interactions, focusing on the differences between standard memory and peripheral addressing.
* **TEST 1: Memory to Memory (`mem->mem`):** Verifies standard block transfers between two standard memory addresses.
* **TEST 2: Peripheral to Memory (`peri->mem`):** Simulates pulling data from a mapped peripheral region (like a UART/FIFO) and writing it into system memory.
* **TEST 3: Peripheral to Peripheral (`peri->peri`):** Validates moving data directly between two mapped peripheral devices.
* **TEST 4: 2D AI Stride Verification: Monitors internal row_count and src_addr


2D Stride Verification Note
During simulation, the m_addr bus may appear to increment by +4 during the WAIT_READ state. This is part of a multi-stage address update:

Incremental Phase: A +4 step occurs upon a successful read to prepare the next word.

Striding Phase: The src_stride is applied cumulatively in the WAIT_WRITE state once row_count reaches row_size.

Verification: Success is confirmed by observing the total address displacement (Delta) between the final word of Row N and the first word of Row N+1 being equal to the programmed stride.