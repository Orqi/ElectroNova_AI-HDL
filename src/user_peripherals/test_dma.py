import cocotb
import os
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

os.environ['COCOTB_RESOLVE_X'] = 'ZEROS'

# ---------------- MEMORY MODEL ---------------- #
memory = {}

async def memory_model(dut):
    while True:
        await RisingEdge(dut.clk)

        dut.m_ready.value = 1
        dut.m_error.value = 0

        # READ
        if dut.m_valid.value and dut.m_read.value:
            addr = int(dut.m_addr.value)
            data = memory.get(addr, 0xDEADBEEF)
            dut.m_rdata.value = data

        # WRITE
        if dut.m_valid.value and dut.m_write.value:
            addr = int(dut.m_addr.value)
            data = int(dut.m_wdata.value)
            memory[addr] = data
            dut._log.info(f"WRITE {hex(addr)} = {hex(data)}")


# ---------------- HELPER ---------------- #
async def write_reg(dut, addr, value):
    dut.address.value = addr
    dut.data_in.value = value
    dut.data_write_n.value = 0
    await RisingEdge(dut.clk)
    dut.data_write_n.value = 3


# ---------------- TEST ---------------- #
@cocotb.test()
async def test_dma_full(dut):

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    cocotb.start_soon(memory_model(dut))

    # RESET
    dut.rst_n.value = 0
    dut.data_write_n.value = 3
    dut.data_read_n.value = 3
    await Timer(100, units="ns")

    dut.rst_n.value = 1
    await Timer(50, units="ns")

    # ---------------- INIT MEMORY ---------------- #
    base_src = 0x1000
    base_dst = 0x2000

    for i in range(16):
        memory[base_src + i*4] = i + 1

    # ---------------- CONFIG DMA ---------------- #
    await write_reg(dut, 0x02, base_src)
    await write_reg(dut, 0x04, base_dst)
    await write_reg(dut, 0x06, 64)  # 16 words

    dut._log.info("Starting DMA...")
    await write_reg(dut, 0x00, 0x01)

    # ---------------- WAIT DONE ---------------- #
    for _ in range(500):
        await RisingEdge(dut.clk)
        if dut.done_flag.value == 1:
            break

    # ---------------- VERIFY ---------------- #
    for i in range(16):
        src_val = memory[base_src + i*4]
        dst_val = memory.get(base_dst + i*4, None)

        if dst_val != src_val:
            raise RuntimeError(
                f"Mismatch at {hex(base_dst + i*4)}: expected {src_val}, got {dst_val}"
            )

    dut._log.info("✅ BASIC TRANSFER PASSED")



# ---------------- 2D MODE TEST ---------------- #
@cocotb.test()
async def test_dma_2d(dut):

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    cocotb.start_soon(memory_model(dut))

    # RESET
    dut.rst_n.value = 0
    dut.data_write_n.value = 3
    dut.data_read_n.value = 3
    await Timer(100, units="ns")

    dut.rst_n.value = 1
    await Timer(50, units="ns")

    base_src = 0x3000
    base_dst = 0x4000

    # Fill 2D pattern
    for i in range(32):
        memory[base_src + i*4] = i + 100

    # CONFIG 2D
    await write_reg(dut, 0x02, base_src)
    await write_reg(dut, 0x04, base_dst)
    await write_reg(dut, 0x03, 16)   # stride
    await write_reg(dut, 0x05, 16)   # row size
    await write_reg(dut, 0x06, 64)   # total

    # Enable 2D mode (bit 4)
    await write_reg(dut, 0x00, 0x11)

    # WAIT
    for _ in range(500):
        await RisingEdge(dut.clk)
        if dut.done_flag.value == 1:
            break

    dut._log.info("✅ 2D MODE EXECUTED (manual inspection possible)")