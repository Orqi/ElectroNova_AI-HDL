# ElectroNova - Challenge [3] Submission

## Team Information
- **Team Name**: ElectroNova
- **Institution**: College of Engineering Trivandrum
- **Division**: [Lower/Upper]
- **Team Members**: 
  - Amrita Reji - Project Lead - contactamreji@gmail.com
  - Vidya S R - Assistant Project Lead - vidyasr2608@gmail.com
  - Amrita M Pillai - System Validation - amritampillai06@gmail.com
  - Karthik M Raj - Documentation - karthikmraj37@gmail.com
- **Mentor**: Sudipta Paria

## Challenge Summary
The objective for DP-3 was to perform a comprehensive Security Assessment and implement Hardware Hardening on our optimized 2D-DMA design. We transformed the IP into a Secure AI Data Gateway by mitigating critical CWE-119 buffer bound vulnerabilities (the "Stride-Jump" exploit) using a custom Hardware Memory Protection Unit (MPU), all while preserving our DP-2 Power, Performance, and Area (PPA) optimizations.

## Key Features
- **Hardware Memory Protection Unit (MPU):** Integrated programmable `OFF_SRC_BOUND` and `OFF_DST_BOUND` registers to enforce strict hardware-level memory isolation.
- **Zero-Latency Bounds Checking:** Real-time combinational security checks evaluate internal registers before master bus assertion, instantly blocking unauthorized access with zero added clock cycles.
- **Legacy Optimization Retention:** The high-throughput 4-word Pipelined FIFO and 2D-Striding logic from DP-2 remain 100% functionally intact and safely secured.

## AI Tools Used
- **Primary LLM:** Google Gemini 3 Flash / Gemini 3.1 Pro
- **Additional tools:** GitHub Copilot
- **Total AI interactions:** 550+

## Results Summary
- **Functionality**: 100% pass rate in both Python (Cocotb) and Native Verilog testbenches, successfully detecting and locking down out-of-bounds security exploit attempts.
- **FPGA/ASIC Implementation**: [Success]
- **Resource Usage**: Optimized RTL allowed the synthesizer to fold security comparators into existing address generation logic, yielding a highly efficient footprint of 1053 LUTs and 573 Flip-Flops.
- **Timing**: Security checks execute concurrently with the FSM, preventing bottlenecks and maintaining the high timing margins achieved in DP-2.

## Innovation Highlights
Our standout innovation is **Internal Register Bounds Checking**. Instead of monitoring the active master bus (`m_addr`), we wired the MPU to evaluate the internal `src_addr` and `dst_addr` registers. This architectural pivot eliminated simulation race conditions and allowed the Yosys synthesizer to aggressively optimize the logic. It proves that with clever datapath design, enterprise-grade hardware security can be implemented without degrading system PPA.

## Team Reflection
DP-3 taught us that hardware security requires a "hacker mindset." Using the STRIDE and DREAD frameworks, we realized our most advanced DP-2 feature (2D Striding) was also our biggest vulnerability. We learned that effective hardware security is about architectural elegance—building safeguards directly into the core logic to protect the System-on-Chip (SoC) without bottlenecking core performance.