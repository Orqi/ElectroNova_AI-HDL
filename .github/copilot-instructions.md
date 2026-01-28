# Copilot Instructions for ElectroNova_AI-HDL

## Project Overview
- This repository implements a RISC-V SoC (TinyQV) and peripherals for the Tiny Tapeout project, with a focus on modular, testable Verilog designs.
- Major directories:
  - `src/`: Core SoC and peripheral Verilog sources
  - `designs/`: Project-specific designs and configuration
  - `test/`: Testbenches, cocotb-based Python tests, and simulation artifacts
  - `docs/`: Documentation, architecture diagrams, and peripheral guides
  - `ElectroNova-challenge-DP#1/`: Challenge submission, logs, and methodology

## Key Workflows
- **Simulation:**
  - Run RTL simulation: `make -C test -B`
  - Gate-level sim: Harden design, copy netlist, then `make -C test -B GATES=yes`
  - View waveforms: `gtkwave test/tb.vcd test/tb.gtkw`
- **Build/Hardening:**
  - Edit `info.yaml` to set `source_files` and `top_module`
  - Run `run_flow.sh` for ASIC build (uses OpenLane)
- **Testbench Adaptation:**
  - Update `test/tb.v` and `test/Makefile` for your module
  - See `test/README.md` for details

## Project Conventions
- **Peripheral Design:**
  - Use the byte or full peripheral template as a starting point
  - Data bus alignment: 8/16-bit data always LSB-aligned in `data_out`/`data_in`
  - Read/write transaction timing: See `docs/wavedrom/` diagrams
- **Documentation:**
  - Update `docs/info.md` and `README.md` to describe your design and test process
  - Submission details in `ElectroNova-challenge-DP#1/`

## Integration & Dependencies
- Uses [OpenLane](https://www.zerotoasiccourse.com/terminology/openlane/) for ASIC flow (via GitHub Actions)
- [cocotb](https://docs.cocotb.org/en/stable/) for Python-based testbenches
- [GTKWave](http://gtkwave.sourceforge.net/) or Surfer for VCD viewing

## Examples
- See `test/test_dma.py` for Python cocotb test structure
- See `src/peripherals.v` for integration of new peripherals
- See `docs/wavedrom/` for transaction protocol diagrams

## Tips for AI Agents
- Always update `info.yaml` and documentation when adding modules
- Follow the data alignment and timing conventions strictly
- Reference `test/README.md` for simulation/test patterns
- Use existing testbenches as templates for new modules

---
For more, see [README.md](../README.md), [docs/info.md](../docs/info.md), and [test/README.md](../test/README.md).
