SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Pointing to the local file we just found
VERILOG_SOURCES += $(PWD)/tqvp_dma.v

TOPLEVEL = tqvp_dma
MODULE = test_dma

include $(shell cocotb-config --makefiles)/Makefile.sim
