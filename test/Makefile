# Custom Makefile for ElectroNova DMA DP#2
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# 1. Only include the files needed for the DMA
VERILOG_SOURCES += $(PWD)/../src/tqvp_dma.v

# 2. Set the Top Level Module name from your Verilog
TOPLEVEL = tqvp_dma

# 3. Set the Python test script name (test_dma.py)
MODULE = test_dma

# 4. Standard Cocotb include
include $(shell cocotb-config --makefiles)/Makefile.sim