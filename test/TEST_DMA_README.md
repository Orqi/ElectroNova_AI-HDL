# DMA Cocotb Test Suite

This directory contains comprehensive cocotb tests for the `tqvp_dma` peripheral integrated with the TinyQV system.

## Prerequisites

- `cocotb` installed (`pip install cocotb`)
- `iverilog` (Icarus Verilog) or another Verilog simulator
- Python 3.7+

## Test Files

- `test_dma.py` — Main cocotb test suite with 6 test cases
- `tb_dma.v` — Pure Verilog testbench (standalone, no cocotb needed)
- `tb_dma_simple.v` — Simplified Verilog testbench for quick verification

## Running the Tests

### Option 1: Standalone Verilog Tests (No Dependencies)

Fastest and simplest. Tests core DMA functionality without cocotb:

```bash
cd test
iverilog -g2009 -o tb_dma.vvp tb_dma.v ../src/user_peripherals/tqvp_dma.v
vvp tb_dma.vvp
```

Expected output:
```
peri->peri verification passed
All tests completed
```

### Option 2: Cocotb Tests (Integrated with TinyQV)

Requires cocotb and a Verilog simulator. Runs through the TinyQV register interface:

```bash
pip install cocotb
cd test
make
```

Or manually:

```bash
cocotb-config --install-lib
iverilog -g2009 -c test_dma.py -m ghdl -o tb_dma -P CLOCK_MHZ=10 tb_dma.v ../src/user_peripherals/tqvp_dma.v
```

## Test Coverage

### Verilog Testbench (`tb_dma.v`)
1. **mem→mem copy** — Transfer data from memory region 1 to region 2
2. **peri→mem copy** — Transfer from peripheral address space to memory
3. **peri→peri copy** — Transfer between peripheral regions

All three pass with verification of written data.

### Cocotb Test Suite (`test_dma.py`)
1. **test_dma_register_access** — Basic read/write of CONTROL, SRC, DST, LEN registers
2. **test_dma_memory_to_memory** — Full mem→mem transfer with interrupt verification
3. **test_dma_interrupt** — IRQ generation and persistence
4. **test_dma_status_register** — Verify busy, done, and error flags
5. **test_dma_register_persistence** — Registers retain values across operations
6. **test_dma_partial_write** — Byte and halfword access patterns

## DMA Register Map

Used by both testbenches:

| Offset | Name | Bits | Description |
|--------|------|------|-------------|
| 0x00 | CONTROL | [7]=clr_err, [3:2]=ch_sel, [1]=irq_en, [0]=start | Control register |
| 0x01 | STATUS | [2]=err, [1]=done, [0]=busy | Status flags |
| 0x02 | SRC_LO | [31:0] | Source address (32-bit) |
| 0x04 | DST_LO | [31:0] | Destination address (32-bit) |
| 0x06 | LEN_LO | [31:0] | Transfer length in bytes (32-bit) |

## CPU/Software Integration

To use the DMA from a C program or RISC-V code:

```c
// Write SRC address
*((volatile uint32_t*)(PERI_BASE + 0x02)) = 0x00000000;

// Write DST address
*((volatile uint32_t*)(PERI_BASE + 0x04)) = 0x00001000;

// Write length (8 bytes)
*((volatile uint32_t*)(PERI_BASE + 0x06)) = 0x00000008;

// Enable interrupt and start
*((volatile uint32_t*)(PERI_BASE + 0x00)) = 0x03;  // irq_en=1, start=1

// Poll for done
while ((*((volatile uint32_t*)(PERI_BASE + 0x01)) & 0x02) == 0) {
    // wait
}
```

## Performance Notes

- **Throughput:** 1 word (32-bit) per ~2 cycles (read + write pipeline)
- **Latency:** ~10 cycles from start to completion for 8-byte transfer
- **Low-power:** `idle` output goes high when DMA inactive (can gate clock)
- **Error handling:** Bus errors (m_error) set err flag and halt transfer

## Debugging

Enable waveform dump in Verilog testbench:

```verilog
initial begin
    $dumpfile("dma_trace.vcd");
    $dumpvars(0, tb_dma);
end
```

Then view with GTKWave:
```bash
gtkwave dma_trace.vcd
```
