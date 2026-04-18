## 📝 AI-HDL Challenge [4] Submission Form

### Basic Information
- **Submission Date**: 2026-04-18
- **Challenge Number**: 4 (Physical Design & System Integration)
- **Team Name**: ElectroNova
- **Team ID**: [assigned during regis]

### Team Members
| Name | Role | Email | Contribution % |
|------|------|-------|----------------|
| Amrita Reji | Project Lead | contactamreji@gmail.com | 85% |
| Vidya S R | Assistant Project Lead | vidyasr2608@gmail.com | 5% |
| Amrita M Pillai | System Validation | amritampillai06@gmail.com | 5% |
| Karthik M Raj | Documentation | karthikmraj37@gmail.com | 5% |

### Design Specifications Met
- [✅] **Final Synthesis Complete**: Targeting Skywater 130nm `sky130_fd_sc_hd` library via Yosys.
- [✅] **Floorplan & PDN Generated**: Optimized 500x500 µm die area with a robust power grid.
- [✅] **Placement & Routing Successful**: Achieved **55.67%** core utilization with **3,591** synthesized cells; resolved all local routing congestion.
- [✅] **Sign-off Verification Passed**: 0 DRC Violations, 0 LVS Errors, and 0 Antenna Violations.
- [✅] **Timing Closure Achieved**: **462.1 MHz** Suggested Clock Frequency; Critical Path of **2.164 ns** verified via OpenSTA.
- [✅] **System Integration Finalized**: Hardware priority arbitrator and CPU stall logic implemented in `project.v`.

### AI Tool Usage Declaration
- **Primary AI Tool**: Google Gemini 3 Pro, Claude, GitHub Copilot
- **Total Conversation Sessions**: 50+ (Cumulative project total)
- **Estimated AI-Generated Code %**: 85% (Focused on FSM refinement, one-shot pulse logic, and physical flow log analysis)
- **Manual Modifications Made**: Yes (Manual refinement of OpenLane `config.json` to enforce Diode Insertion Strategy 3; iterative tuning of `PL_TARGET_DENSITY` to 0.41 to balance cell density with 32-bit routing channels; manual instantiation of latched shadow registers).

### Special Considerations
- **Bonus Features Implemented**: 
    - **Atomic Register Latching**: Tiling parameters (`src_stride`, `row_size`) are hardware-locked at launch, ensuring AI workload determinism and immunity to mid-transfer CPU interference.
    - **High-Priority Bus Arbitration**: Engineered a "Ready-Stall" mechanism in the system top-level to halt the TinyQV CPU during active DMA bursts.
- **Physical Reliability**: Achieved 100% antenna-clean sign-off by inserting **2,412** protective diodes across the pipelined datapath.
- **Security Persistence**: Verified that the Hardware Memory Protection Unit (MPU) maintained zero-latency trapping post-physical routing.

### Verification Checklist
- [✅] **Manufacturable Layout**: Final GDSII file generated (`tqvp_dma.gds`).
- [✅] **DRC Report Clean**: Verified via Magic (`drc.rpt`).
- [✅] **LVS Report Clean**: Verified via Netgen (`43-tqvp_dma.lvs.rpt`).
- [✅] **Static Timing Analysis Passed**: Verified via OpenSTA (`33-sta-rcx_max.rpt`).
- [✅] **System Integration Verified**: Waveform proof showing CPU stall and 2D-stride address jump (e.g., `0x1004` to `0x1100`).

### Team Statement
We certify that this submission represents our original work, culminating in the physical tape-out of the ElectroNova Secure 2D-DMA. Using the OpenLane flow, the design has been taken from architecture to a physically verified macro that is DRC and LVS clean. The final implementation achieves a suggested operating frequency of 462.1 MHz, meeting and exceeding the requirements for the TinyQV SoC while maintaining the intended hardware security features.

**Team Representative**: Amrita Reji  
**Date**: 2026-04-18