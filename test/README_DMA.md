DMA peripheral test README

Run the DMA testbench (requires Icarus Verilog):

1) From the project root run:

```bash
iverilog -o tb_dma.vvp test/tb_dma.v src/user_peripherals/tqvp_dma.v
vvp tb_dma.vvp
```

2) The testbench executes three tests:
- Memory-to-memory copy
- Peripheral-to-memory copy (peripheral region simulated in memory)
- Peripheral-to-peripheral copy

3) The testbench prints verification results; errors are displayed as messages.

Integration notes
- To enable the DMA in your SoC, instantiate `tqvp_dma` in `src/peripherals.v` as a user peripheral slot and wire the `m_*` master signals to your memory/bus interconnect. See `src/user_peripherals/dma_README.md` for register map and example wiring.
