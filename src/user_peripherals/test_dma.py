import cocotb
import os
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

os.environ['COCOTB_RESOLVE_X'] = 'ZEROS'

async def dummy_memory_slave(dut):
    """Simulate Memory Responding to DMA Reads and Writes"""
    while True:
        await RisingEdge(dut.clk)
        dut.m_ready.value = 1
        
        # If the DMA tries to READ, give it dummy data and acknowledge
        if hasattr(dut, 'm_read') and getattr(dut.m_read, 'value', 0) == 1:
            if hasattr(dut, 'data_in'): dut.data_in.value = 0xDEADBEEF
            if hasattr(dut, 'mem_valid'): dut.mem_valid.value = 1
        else:
            if hasattr(dut, 'mem_valid'): dut.mem_valid.value = 0

@cocotb.test()
async def test_dma_performance(dut):
    """Verify DMA Stream via Bus Interface"""
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    cocotb.start_soon(dummy_memory_slave(dut))

    # 1. Initialize System Signals
    dut.rst_n.value = 0
    # Initialize the Slave Bus (CPU to Peripheral interface)
    if hasattr(dut, 'bus_valid'): dut.bus_valid.value = 0
    if hasattr(dut, 'bus_addr'): dut.bus_addr.value = 0
    if hasattr(dut, 'bus_wdata'): dut.bus_wdata.value = 0
    if hasattr(dut, 'bus_wstrb'): dut.bus_wstrb.value = 0
    
    await Timer(200, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    
    # 2. Configure via Slave Bus (Assuming standard register map)
    # Write Source Addr (Offset 0x04)
    if hasattr(dut, 'bus_valid'):
        await RisingEdge(dut.clk)
        dut.bus_addr.value = 0x04
        dut.bus_wdata.value = 0x1000
        dut.bus_wstrb.value = 0xF
        dut.bus_valid.value = 1
        await RisingEdge(dut.clk)
        dut.bus_valid.value = 0
        
        # Write Dest Addr (Offset 0x08)
        await RisingEdge(dut.clk)
        dut.bus_addr.value = 0x08
        dut.bus_wdata.value = 0x2000
        dut.bus_wstrb.value = 0xF
        dut.bus_valid.value = 1
        await RisingEdge(dut.clk)
        dut.bus_valid.value = 0
        
        # Write Length (Offset 0x0C)
        await RisingEdge(dut.clk)
        dut.bus_addr.value = 0x0C
        dut.bus_wdata.value = 64
        dut.bus_wstrb.value = 0xF
        dut.bus_valid.value = 1
        await RisingEdge(dut.clk)
        dut.bus_valid.value = 0
        
        # Write Control/Start (Offset 0x00)
        await RisingEdge(dut.clk)
        dut._log.info("Sending Start Command via Bus...")
        dut.bus_addr.value = 0x00
        dut.bus_wdata.value = 0x01 # Start bit
        dut.bus_wstrb.value = 0xF
        dut.bus_valid.value = 1
        await RisingEdge(dut.clk)
        dut.bus_valid.value = 0
    else:
        # Fallback if there is no bus interface
        dut.src_addr.value = 0x1000
        dut.dst_addr.value = 0x2000
        dut.length.value = 64
        if hasattr(dut, 'start_r'):
            dut._log.info("Sending Start Pulse Directly...")
            dut.start_r.value = 1
            await RisingEdge(dut.clk)
            dut.start_r.value = 0

    # 3. Wait for m_valid (The Write Output)
    for i in range(200): # Allow time for pipeline to fill
        await RisingEdge(dut.clk)
        if str(dut.m_valid.value) == '1':
            addr = int(dut.m_addr.value)
            dut._log.info(f"🏆 SUCCESS: DMA Pipeline is streaming! Write Address: {hex(addr)}")
            return

    # If it fails, dump state
    read_req = dut.m_read.value if hasattr(dut, 'm_read') else "N/A"
    write_req = dut.m_write.value if hasattr(dut, 'm_write') else "N/A"
    fifo_cnt = dut.fifo_count.value if hasattr(dut, 'fifo_count') else "N/A"
    state = dut.state.value if hasattr(dut, 'state') else "N/A"
    raise RuntimeError(f"DMA hung. state={state}, read={read_req}, write={write_req}, fifo={fifo_cnt}")
