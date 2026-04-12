## 📝 AI-HDL Challenge [3] Submission Form

### Basic Information
- **Submission Date**: 2026-04-13
- **Challenge Number**: 3 (Security Assessment & Hardening)
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
- [✅] Security Assessment Complete (CIA, STRIDE, DREAD analysis documented)
- [✅] Countermeasure Implemented (Hardware Memory Protection Unit - MPU)
- [✅] Validation Successful (Cocotb & Native Verilog simulate 100% exploit blockage)
- [✅] PPA Overhead Analyzed (Logic synthesis optimized to 1053 LUTs; Zero timing penalty)
- [✅] DP-2 Features Preserved (Pipelined FIFO, Precise Byte Strobes, 2D Striding remain fully functional)

### AI Tool Usage Declaration
- **Primary AI Tool**: Google Gemini 3.1 Pro, GitHub Copilot
- **Total Conversation Sessions**: 550+
- **Estimated AI-Generated Code %**: 65% (Architectural refactoring for security and testbench generation)
- **Manual Modifications Made**: Yes (Architectural pivot: modifying `addr_fault` to evaluate internal state registers instead of the multiplexed master bus to eliminate zero-delay simulation race conditions).

### Special Considerations
- **Bonus Features Implemented**: The security guard logic was optimized by the Yosys synthesizer to *reduce* the overall DP-2 area footprint by 55 logic gates while increasing system security.
- **Threat Model Focus**: CWE-119 (Improper Restriction of Memory Buffer Bounds) via "Stride-Jump" exploit.
- **Future Improvements**: Integration with a dynamic privilege-level bus fabric (e.g., AXI TrustZone) to allow run-time boundary updates from secure OS kernels.

### Verification Checklist
- [✅] Security Threat Model (STRIDE/DREAD) Documented
- [✅] RTL Hardware Fix Implemented (`tqvp_dma.v`)
- [✅] Python/Cocotb Testbench proves exploit blocked (`test_dma.py`)
- [✅] Native Verilog Testbench proves exploit blocked (`tb_dma.v`)
- [✅] Physical Synthesis re-run to confirm PPA impact (`metrics.csv`)

### Team Statement
We certify that this submission represents our original work, specifically focused on the security hardening of our high-performance DP-2 DMA. We successfully mitigated a critical hardware exploit vector by architecting a zero-latency Memory Protection Unit, transforming the design into a Secure AI Data Gateway ready for silicon integration.

**Team Representative**: Amrita Reji  
**Date**: 2026-04-13