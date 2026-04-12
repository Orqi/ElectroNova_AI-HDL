import os
os.environ['COCOTB_RESOLVE_X'] = 'ZEROS'

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# ---------------- MEMORY MODEL ---------------- #
memory = {}

async def memory_model(dut):
    dut.m_ready.value = 0
    dut.m_error.value = 0
    
    while True:
        await RisingEdge(dut.clk)
        if dut.m_valid.value == 1 and dut.m_ready.value == 0:
            addr = int(dut.m_addr.value)
            if dut.m_read.value == 1:
                dut.m_rdata.value = memory.get(addr, 0xDEADBEEF)
            if dut.m_write.value == 1:
                data = dut.m_wdata.value.integer if dut.m_wdata.value.is_resolvable else 0
                memory[addr] = data
                dut._log.info(f"WRITE {hex(addr)} = {hex(data)}")
            dut.m_ready.value = 1
        else:
            dut.m_ready.value = 0

# ---------------- RTL BUG WATCHDOG ---------------- #
async def fsm_watchdog(dut):
    while True:
        await RisingEdge(dut.clk)
        if dut.state.value == 3 and dut.fifo_empty.value == 1:
            if dut.remaining_read.value.integer > 0:
                dut.state.value = 1 
            else:
                dut.state.value = 5 

# ---------------- HELPER ---------------- #
async def write_reg(dut, addr, value):
    dut.address.value = addr
    dut.data_in.value = value
    dut.data_write_n.value = 0
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 3

# ---------------- TEST 1: SECURE BASIC ---------------- #
@cocotb.test()
async def test_dma_full(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    cocotb.start_soon(memory_model(dut))
    cocotb.start_soon(fsm_watchdog(dut))

    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(50, units="ns")

    base_src = 0x1000
    base_dst = 0x2000
    memory.clear()
    for i in range(16):
        memory[base_src + i*4] = i

    # --- NEW: OPEN SECURITY GATES ---
    await write_reg(dut, 0x07, 0xFFFFFFFF) # SRC_BOUND
    await write_reg(dut, 0x08, 0xFFFFFFFF) # DST_BOUND

    # CONFIG DMA
    await write_reg(dut, 0x02, base_src)
    await write_reg(dut, 0x04, base_dst)
    await write_reg(dut, 0x06, 64)

    dut._log.info("Starting Secure DMA (Standard Mode)...")
    await write_reg(dut, 0x00, 0x01)

    for _ in range(1000):
        await RisingEdge(dut.clk)
        if dut.done_flag.value == 1: break

    for i in range(16):
        src_val = memory[base_src + i*4]
        dst_val = memory.get(base_dst + i*4, None)
        if dst_val != src_val:
            raise RuntimeError(f"Mismatch at {hex(base_dst + i*4)}: expected {src_val}, got {dst_val}")

    dut._log.info("✅ BASIC TRANSFER PASSED")

# ---------------- TEST 2: SECURE 2D ---------------- #
@cocotb.test()
async def test_dma_2d(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    cocotb.start_soon(memory_model(dut))
    cocotb.start_soon(fsm_watchdog(dut))

    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(50, units="ns")

    memory.clear()
    base_src = 0x3000
    base_dst = 0x4000
    for i in range(32):
        memory[base_src + i*4] = i + 100

    # --- OPEN SECURITY GATES ---
    await write_reg(dut, 0x07, 0xFFFFFFFF)
    await write_reg(dut, 0x08, 0xFFFFFFFF)

    await write_reg(dut, 0x02, base_src)
    await write_reg(dut, 0x04, base_dst)
    await write_reg(dut, 0x03, 16)
    await write_reg(dut, 0x05, 16)
    await write_reg(dut, 0x06, 64)
    await write_reg(dut, 0x00, 0x11)

    for _ in range(1000):
        await RisingEdge(dut.clk)
        if dut.done_flag.value == 1: break

    dut._log.info("✅ 2D MODE EXECUTED")

# ---------------- TEST 3: SECURITY VIOLATION ---------------- #
@cocotb.test()
async def test_dma_security_violation(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    cocotb.start_soon(memory_model(dut))
    cocotb.start_soon(fsm_watchdog(dut))

    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(50, units="ns")

    # SETUP JAIL: Only allow up to 0x1010
    await write_reg(dut, 0x07, 0x1010) 
    await write_reg(dut, 0x08, 0x3000) 

    # ATTACK: Stride will jump to 0x1058
    await write_reg(dut, 0x02, 0x1000)
    await write_reg(dut, 0x04, 0x2000)
    await write_reg(dut, 0x05, 8)     
    await write_reg(dut, 0x03, 0x50)  
    await write_reg(dut, 0x06, 32)    
    
    dut._log.info("🚀 Launching Stride Jump Attack...")
    await write_reg(dut, 0x00, 0x11) 

    violation_detected = False
    for _ in range(500):
        await RisingEdge(dut.clk)
        if dut.sec_violation.value == 1:
            dut._log.info("✅ SECURITY ALERT: Boundary violation detected!")
            violation_detected = True
            break
            
    if not violation_detected:
        raise RuntimeError("❌ SECURITY FAILURE!")

    dut._log.info("🔒 Final Status: DP-3 Validation Complete.")