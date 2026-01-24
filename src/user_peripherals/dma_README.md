tqvp_dma integration notes

Overview
- `tqvp_dma.v` provides a memory-mapped DMA peripheral exposing a register interface compatible with the other full user peripherals in `src/peripherals.v`.
- It also exposes an optional master bus interface (`m_addr`, `m_wdata`, `m_wstrb`, `m_write`, `m_read`, `m_valid`, `m_rdata`, `m_ready`, `m_error`) which must be wired to the system memory/bus for the DMA to actually move data.

Register map (offset = low 6 bits of peripheral address)
- 0x00 CONTROL : bit0=start, bit1=irq_en, bits3:2=channel select, bit7=clear error
- 0x01 STATUS  : bit0=busy, bit1=done, bit2=err
- 0x02 SRC_LO  : src address (32-bit read/write)
- 0x04 DST_LO  : dst address (32-bit read/write)
- 0x06 LEN_LO  : transfer length in bytes (32-bit)

Behavior
- Write CONTROL/start=1 to start a transfer described by SRC/DST/LEN.
- `user_interrupt` asserts when `irq_en` and transfer completes or error occurs.
- `idle` goes high when DMA is not active (can be used for low-power gating externally).
- Error detection: the module monitors `m_error` from the bus; on error it sets `err` and stops.

Integration snippet (example) — add to `src/peripherals.v` in place of an unused user peripheral slot (slot 0 is commonly free):

```verilog
// Example instantiation (named port mapping)
tqvp_dma i_user_peri00 (
    .clk(clk),
    .rst_n(rst_n),

    .ui_in(ui_in),
    .uo_out(uo_out_from_user_peri[0]),

    .address(addr_in[5:0]),
    .data_in(data_in),

    .data_write_n(data_write_n    | {2{~peri_user[0]}}),
    .data_read_n(data_read_n_peri | {2{~peri_user[0]}}),

    .data_out(data_from_user_peri[0]),
    .data_ready(data_ready_from_user_peri[0]),

    .user_interrupt(user_interrupts[0]),

    // Master bus signals — wire to your system memory/bus
    .m_addr(dma_m_addr),
    .m_wdata(dma_m_wdata),
    .m_wstrb(dma_m_wstrb),
    .m_write(dma_m_write),
    .m_read(dma_m_read),
    .m_valid(dma_m_valid),
    .m_rdata(dma_m_rdata),
    .m_ready(dma_m_ready),
    .m_error(dma_m_error),

    .idle(dma_idle)
);
```

Notes
- This patch does not modify `src/peripherals.v`; to actually enable the DMA you must instantiate it in the chosen user peripheral slot (example above).
- The master bus interface is intentionally simple; adapt the names to your on-chip bus or add a thin adapter to convert to your system's protocol.
