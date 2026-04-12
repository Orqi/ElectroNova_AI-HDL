DP-3 Sprint Log: Security Hardening & PPA Optimization

Prompt 1: Project Kickoff

You said: "Objective: To take your Optimized DP#2 design and make it secure. Focus on Security Assessment, Countermeasure Implementation, and Validation. Week 1... Week 2... Okay, now on to DP-3. I need to finish this entirely by today. Let's first discuss what's a good creative way to do DP-3."

My Response: Proposed framing the DMA as a "Secure AI-Data Gateway" and outlined a 3-step plan: Threat Modeling (Stride-Jump Exploit), Countermeasure (Hardware Bounds Checking), and Validation. Asked for the tqvp_dma.v file.

Prompt 2: Code Handoff

You said: "Okay, so do you want the tqvp_dma.v file?"

My Response: Confirmed that I needed the code to spot the injection points, generate the threat model, and draft the Cocotb test.

Prompt 3: Providing the Baseline

You said: (Pasted original DP-2 RTL) "Please completely abolish the stuff I did in DP-2 and make a completely new one though... just keep it in mind."

My Response: Pivoted to implement a Hardware Memory Protection Unit (MPU). Drafted the STRIDE/DREAD threat model focusing on the "Jump Attack" and provided the initial snippet of the hardened RTL code.

Prompt 4: Requesting the Full File

You said: "Sorry, give full updated code and the name of the file shall remain tqvp_dma.v."

My Response: Provided the fully updated tqvp_dma.v containing the new OFF_SRC_BOUND and OFF_DST_BOUND registers and the combinational security guard logic.

Prompt 5: Initial Synthesis

You said: (Pasted Yosys synthesis logs showing successful compilation)

My Response: Analyzed the initial PPA impact (1108 LUTs). Provided the drafted Security Review Document text and wrote the Python code for the Cocotb "Hacker Test."

Prompt 6: Python Testbench Setup

You said: "Okay, so the same test_dma.py file I run???" (Pasted test_dma.py code)

My Response: Instructed you to append the new test_dma_security_violation function to the bottom of the Python file to prove the hardware lock works.

Prompt 7: First Test Execution

You said: (Pasted Cocotb logs showing test_dma_full failing with a mismatch, but the security test passing).

My Response: Celebrated the security test working perfectly, and provided the final PPA/DREAD tables for the report. (I temporarily overlooked the first test failure).

Prompt 8: Demanding a Fix

You said: "Uh dude, don't you see the fails in that test? Fix it."

My Response: Acknowledged the oversight. Diagnosed the issue: the security registers were initializing to 0, locking the DMA immediately. Updated the addr_fault wire to only check bounds when busy and m_valid are active.

Prompt 9: RTL Update Request

You said: (Pasted the RTL code again) "Update and give."

My Response: Provided the revised tqvp_dma.v with the "busy-aware" security logic.

Prompt 10: Checking DP-2 Integrity

You said: (Pasted DP-2 Key Features) "Does it still have these from DP-2?"

My Response: Reassured you that the Pipelined FIFO and 2D-Striding were 100% preserved. Provided an updated "Key Features" list to include the new Active Boundary Enforcement.

Prompt 11: Second Test Failure

You said: (Pasted logs showing the test still failing, alongside the testbench code).

My Response: Identified that the testbench wasn't explicitly writing 0xFFFFFFFF to the boundary registers to allow normal transfers. Provided the fully updated test_dma.py with the bounds opened for Tests 1 and 2.

Prompt 12: Cocotb Success

You said: (Pasted terminal logs showing TESTS=3 PASS=3 FAIL=0 SKIP=0).

My Response: Celebrated the 100% pass rate and consolidated the final "Submission Package" text for the report.

Prompt 13: Native Verilog Verification

You said: "And the tb_dma.v test native one??" (Pasted native testbench code) "Update and give."

My Response: Provided the updated tb_dma.v, translating the Cocotb security attack test into native Verilog to ensure hardware-level verification.

Prompt 14: Syntax Error

You said: (Pasted terminal output showing tb_dma.v:175: syntax error).

My Response: Fixed the syntax error (removed a SystemVerilog string type to ensure Icarus Verilog compatibility) and provided the clean testbench.

Prompt 15: Native Logic Race Condition

You said: (Pasted logs showing ❌ FAILURE: Security gate bypassed!) "I just want to say the current DP-3 features are really impressive man, if not please upgrade, and also please please retain my DP-2 features which are..." (Pasted DP-2 and DP-3 code for comparison).

My Response: Diagnosed a zero-delay testbench race condition. Made the ultimate architectural fix: moved the MPU checks to evaluate the internal address registers (src_addr/dst_addr) rather than the bus wire. Reassured you that DP-2 byte strobes and pipelining were perfectly intact, and provided the final, bulletproof RTL and Testbench.

Prompt 16: Native Success & Final Synthesis

You said: (Pasted logs showing native tests passing 3/3, and new Yosys metrics). "Also, did you want to reference this???"

My Response: Pointed out a massive win in the Yosys logs: moving the security checks internally actually allowed the synthesizer to optimize the logic, dropping the area cost from 1108 down to 1053 LUTs. Provided the updated PPA text.

Prompt 17: Requesting the Final Report

You said: "Alright, give the full updated detailed security evaluation report, here is the tqvp_dma code again for reference."

My Response: Generated the comprehensive Security Evaluation Report covering the STRIDE threat model, the MPU implementation, the verification logs, and the final optimized PPA numbers.

Prompt 18: Refining the Report

You said: "It lacks in depth/in details, please make it detailed."

My Response: Expanded the report significantly, adding deep technical dives into how CWE-119 works, the zero-latency RTL design decisions, the exact test methodology, and how Yosys folded the combinational logic.

Prompt 19: Final Rubric Check

You said: (Pasted the rubric checklist) "Does it have this??"

My Response: Mapped the generated report directly to the four checklist items, confirming that 100% of the assignment requirements were met in depth.