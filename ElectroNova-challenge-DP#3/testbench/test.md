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

ypes of Tests Conducted
The DMA module (tqvp_dma) is validated using two distinct testing environments to ensure robust hardware behavior and security enforcement. Both test suites include an FSM Watchdog to automatically bypass a known RTL deadlock bug in the ISSUE_WRITE state.

🛡️ Security Note for DP-3: By default, the DMA boots into a total hardware lockdown. All functional tests must explicitly write 0xFFFFFFFF to the OFF_SRC_BOUND and OFF_DST_BOUND registers to "open the gates" before initiating a transfer.

1. Python/Cocotb Test Suite (test_dma.py)

This suite uses Python to act as a virtual RISC-V processor and memory bus, interacting with the Verilog DMA module.

Secure Basic 1D Transfer (test_dma_full): Validates standard linear memory copying (16 words) from a base source to a base destination with the security gates fully opened.

Secure 2D Strided Transfer (test_dma_2d): Tests the advanced AI-HDL 2D striding logic within legal memory boundaries. It verifies that the DMA can safely jump to next rows (src_stride) after hitting the configured row_size.

Security Violation Attack (test_dma_security_violation): Simulates a "Stride-Jump" exploit. Programs the DMA into a restricted memory jail (0x1010) and attempts a malicious stride jump to an unauthorized address (0x1058). Proves the hardware intercepts the calculation and halts the DMA instantly.

2. Native Verilog Testbench (tb_dma.v)

This suite simulates pure hardware-level interactions to verify that the FSM and Memory Protection Unit (MPU) operate correctly without zero-delay Python artifacts.

TEST 1: Standard Copy: Verifies standard 1D block transfers using standard memory addressing while the security bounds are temporarily disabled.

TEST 5: Hardware Security Lock: Strictly validates the MPU at the RTL level. The test locks the source boundary to 0x10 and attempts a read at 0x200. Confirms that bit 3 of the OFF_STATUS register (sec_violation) is successfully latched and the bus is blocked.