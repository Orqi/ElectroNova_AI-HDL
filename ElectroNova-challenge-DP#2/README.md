# ElectroNova - Challenge [X] Submission

## Team Information
- **Team Name**: ElectroNova
- **Institution**: College of Engineering Trivandrum
- **Division**: [Lower/Upper]
- **Team Members**: 
  - Amrita Reji - Project Lead - contactamreji@gmail.com
  - Vidya S R - Assistant project lead - vidyasr2608@gmail.com
  - Amrita M Pillai - System validation - amritampillai06@gmail.com
  - Karthik M Raj - Documentation - karthikmraj37@gmail.com
- **Mentor**: Sudipta Paria

## Challenge Summary
The objective was to take our functional 2D-DMA design and optimize it for Power, Performance, and Area (PPA) within a physical synthesis flow. Our approach focused on transforming the RTL into a silicon-ready GDSII using the OpenLane flow. We transitioned from a baseline 1D-serial copier to an optimized 2D-strided pipelined architecture, balancing logic density with physical reliability by eliminating all antenna violations and maintaining a high timing margin for the TinyQV system.



## Key Features
- **Pipelined Data Path:** Optimized the 4-word FIFO buffering to ensure concurrent read/write operations, doubling bus utilization compared to the serial baseline.
- **2D-Stride Address Generation:** Implemented hardware-level row-jumping logic (stride) to offload complex non-contiguous memory mapping from the CPU.
- **Physical Reliability Signoff:** Successfully eliminated all 29 baseline antenna violations using Diode Strategy 3, achieving a 100% clean manufacturability report.



## AI Tools Used
- **Primary LLM:** Google Gemini 3 Flash
- **Additional tools:** GitHub Copilot
- **Total AI interactions:** 200+

## Results Summary
- **Functionality**: Passed all functional tests including 2D-stride address jump verification and master bus handshaking.
- **FPGA Implementation**: [Success]
- **Resource Usage**: 2,734 Synthesis Cells; Final Core Utilization: 18.73% (Strategic 6.2% increase for 2D math and 2,412 protective diodes).
- **Timing**: 30.34 ns Worst-Case Slack achieved on a 40ns period (Max Frequency: 153.18 MHz).



## Innovation Highlights
Our solution is unique in its "Race-to-Sleep" optimization strategy. While the baseline design moved data linearly, our optimized 2D-engine allows the system to complete complex tiling tasks significantly faster. By investing 1.18mW of typical power into 2D-addressing logic and protective diodes, we transformed a simple peripheral into a high-performance, tapeout-ready IP block that maximizes system-level energy efficiency.



## Team Reflection
This challenge taught us that PPA optimization is about making smart trade-offs. We learned that "Area efficiency" doesn't always mean the smallest footprint; it means using the available silicon to add critical reliability (diodes) and performance (FIFO). Validating our 2D-DMA through the OpenLane signoff reports (STA and Power) proved that architectural complexity can be implemented without compromising physical timing or manufacturability.