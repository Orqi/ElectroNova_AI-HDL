# AI-HDL Challenge [2] Submission Form

## Basic Information
- **Submission Date**: 2026-03-01
- **Challenge Number**: 2
- **Team Name**: ElectroNova
- **Team ID**: [assigned during regis]

## Team Members
| Name | Role | Email | Contribution % |
|------|------|-------|----------------|
| Amrita Reji | Project Lead | contactamreji@gmail.com | 50% |
| Vidya S R | Assistant Project Lead | vidyasr2608@gmail.com | 30% |
| Amrita M Pillai | System Validation | amritampillai06@gmail.com | 10% |
| Karthik M Raj | Documentation | karthikmraj37@gmail.com | 10% |

## Design Specifications Met
- [✅] All required functionality implemented (2D-Stride logic verified)
- [✅] FPGA implementation successful (N/A - ASIC/OpenLane focused flow)
- [✅] Timing requirements met (30.34ns Slack / 153MHz Max Freq)
- [✅] Resource constraints satisfied (18.73% Core Utilization)
- [✅] All test cases pass (GDSII Sign-off complete)

## AI Tool Usage Declaration
- **Primary AI Tool**: Google Gemini 3 Flash, GitHub Copilot
- **Total Conversation Sessions**: 500+
- **Estimated AI-Generated Code %**: 60% (Architectural refinement and STA scripts)
- **Manual Modifications Made**: Yes (Manual floorplanning and antenna diode strategy 3 selection)

## Special Considerations
- **Bonus Features Implemented**: 2D-Strided Address Generation, 4-Word Pipelined FIFO, 100% Clean Physical Sign-off (Zero Antenna Violations).
- **Known Issues**: None; design passed LVS and DRC checks in Sky130.
- **Future Improvements**: Implementation of Multi-Channel Round-Robin Arbitration for parallel 2D streams.

## Verification Checklist
- [✅] All source files compile without errors
- [✅] Testbenches run successfully (STA Max/Min corners verified)
- [✅] ASIC implementation verified via OpenLane GDSII flow
- [✅] AI interaction logs are complete
- [✅] Documentation is thorough and clear

## Team Statement
We certify that this submission represents our original work, specifically focused on the PPA optimization of our functional DMA from DP#1. We successfully transitioned the design to a tapeout-ready state with a 1.18mW power profile and a robust physical layout.

**Team Representative**: Amrita Reji
**Date**: 2026-03-01