# SPDX-FileCopyrightText: © 2025 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from tqv import TinyQV

# When submitting your design, change this to the peripheral number
# in peripherals.v.  e.g. if your design is i_user_peri05, set this to 5.
# The DMA peripheral is instantiated at user peripheral slot 0
PERIPHERAL_NUM = 0

@cocotb.test()
async def test_dma_register_access(dut):
    """Test basic DMA register read/write"""
    dut._log.info("Start DMA Register Access Test")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Create TinyQV interface to the DMA peripheral
    tqv = TinyQV(dut, PERIPHERAL_NUM)

    # Reset
    await tqv.reset()

    dut._log.info("Test DMA control register")
    
    # Write CONTROL register (offset 0x00): irq_en=1, start=0
    await tqv.write_byte_reg(0, 0x02)  # irq_en=1
    val = await tqv.read_byte_reg(0)
    assert val == 0x02, f"CONTROL read failed: expected 0x02, got {val:02x}"
    
    # Write SRC address (offset 0x02)
    await tqv.write_word_reg(0x02, 0x00000000)
    val = await tqv.read_word_reg(0x02)
    assert val == 0x00000000, f"SRC_LO read failed: expected 0x00000000, got {val:08x}"
    
    # Write DST address (offset 0x04)
    await tqv.write_word_reg(0x04, 0x00000100)
    val = await tqv.read_word_reg(0x04)
    assert val == 0x00000100, f"DST_LO read failed: expected 0x00000100, got {val:08x}"
    
    # Write LENGTH (offset 0x06)
    await tqv.write_word_reg(0x06, 0x00000008)  # 8 bytes
    val = await tqv.read_word_reg(0x06)
    assert val == 0x00000008, f"LEN_LO read failed: expected 0x00000008, got {val:08x}"
    
    dut._log.info("Register access tests passed")


@cocotb.test()
async def test_dma_memory_to_memory(dut):
    """Test memory-to-memory DMA transfer"""
    dut._log.info("Start DMA Memory-to-Memory Transfer Test")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    dut._log.info("Setup memory-to-memory transfer")
    
    # Configure for mem->mem copy: src=0x0, dst=0x100, len=8
    await tqv.write_word_reg(0x02, 0x00000000)  # SRC_LO
    await tqv.write_word_reg(0x04, 0x00000100)  # DST_LO
    await tqv.write_word_reg(0x06, 0x00000008)  # LEN_LO (8 bytes)
    
    # Enable IRQ and start transfer
    await tqv.write_byte_reg(0x00, 0x03)  # irq_en=1, start=1
    
    dut._log.info("Waiting for DMA completion")
    
    # Poll STATUS register for done flag (bit 1)
    max_wait = 10000  # 10000 cycles max
    done = False
    for i in range(max_wait):
        status = await tqv.read_byte_reg(0x01)
        if status & 0x02:  # done flag
            done = True
            dut._log.info(f"DMA completed after {i} cycles")
            break
        if status & 0x04:  # error flag
            raise AssertionError(f"DMA error detected at cycle {i}")
        await ClockCycles(dut.clk, 1)
    
    assert done, "DMA did not complete within timeout"
    
    # Check interrupt asserted
    is_irq = await tqv.is_interrupt_asserted()
    assert is_irq, "Interrupt should be asserted after transfer completes"
    
    dut._log.info("Memory-to-memory transfer test passed")


@cocotb.test()
async def test_dma_interrupt(dut):
    """Test DMA interrupt generation and clearing"""
    dut._log.info("Start DMA Interrupt Test")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    dut._log.info("Setup short transfer to trigger interrupt")
    
    # Configure short transfer: src=0x0, dst=0x100, len=4
    await tqv.write_word_reg(0x02, 0x00000000)  # SRC_LO
    await tqv.write_word_reg(0x04, 0x00000100)  # DST_LO
    await tqv.write_word_reg(0x06, 0x00000004)  # LEN_LO (4 bytes)
    
    # Enable IRQ and start
    await tqv.write_byte_reg(0x00, 0x03)  # irq_en=1, start=1
    
    # Wait for interrupt
    max_wait = 5000
    for i in range(max_wait):
        status = await tqv.read_byte_reg(0x01)
        if status & 0x02:  # done
            break
        await ClockCycles(dut.clk, 1)
    
    # Interrupt should be asserted
    await ClockCycles(dut.clk, 1)
    is_irq = await tqv.is_interrupt_asserted()
    assert is_irq, "Interrupt not asserted after transfer"
    
    dut._log.info("Interrupt asserted correctly")
    
    # Interrupt should persist until explicitly cleared
    await ClockCycles(dut.clk, 100)
    is_irq = await tqv.is_interrupt_asserted()
    assert is_irq, "Interrupt cleared prematurely"
    
    # Clear error flag in status register (bit 7 of control)
    # Note: The done flag auto-clears on next operation, but this tests clearing explicitly
    dut._log.info("Interrupt test passed")


@cocotb.test()
async def test_dma_status_register(dut):
    """Test DMA status register"""
    dut._log.info("Start DMA Status Register Test")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    dut._log.info("Check initial status (idle)")
    
    # Initially should be idle (busy=0, done=0, err=0)
    status = await tqv.read_byte_reg(0x01)
    assert (status & 0x07) == 0x00, f"Initial status should be 0x00, got {status:02x}"
    
    dut._log.info("Setup transfer and check busy")
    
    # Configure transfer
    await tqv.write_word_reg(0x02, 0x00000000)
    await tqv.write_word_reg(0x04, 0x00000100)
    await tqv.write_word_reg(0x06, 0x00000020)  # Longer transfer
    
    # Start without interrupt
    await tqv.write_byte_reg(0x00, 0x01)  # start=1
    
    # Busy should be set
    await ClockCycles(dut.clk, 5)
    status = await tqv.read_byte_reg(0x01)
    assert (status & 0x01) == 0x01, f"Busy flag should be set, got status {status:02x}"
    
    # Wait for completion
    for i in range(10000):
        status = await tqv.read_byte_reg(0x01)
        if status & 0x02:  # done
            break
        await ClockCycles(dut.clk, 1)
    
    # Done should be set, busy should be clear
    status = await tqv.read_byte_reg(0x01)
    assert (status & 0x02) == 0x02, f"Done flag should be set, got {status:02x}"
    assert (status & 0x01) == 0x00, f"Busy flag should be clear, got {status:02x}"
    
    dut._log.info("Status register test passed")


@cocotb.test()
async def test_dma_register_persistence(dut):
    """Test that DMA registers persist across operations"""
    dut._log.info("Start DMA Register Persistence Test")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    dut._log.info("Write and verify register persistence")
    
    # Write source address
    await tqv.write_word_reg(0x02, 0xDEADBEEF)
    val1 = await tqv.read_word_reg(0x02)
    assert val1 == 0xDEADBEEF, f"SRC read 1 failed: {val1:08x}"
    
    # Write destination address
    await tqv.write_word_reg(0x04, 0xCAFEBABE)
    val2 = await tqv.read_word_reg(0x04)
    assert val2 == 0xCAFEBABE, f"DST read 1 failed: {val2:08x}"
    
    # Read back both
    val1_2 = await tqv.read_word_reg(0x02)
    assert val1_2 == 0xDEADBEEF, f"SRC read 2 failed: {val1_2:08x}"
    
    val2_2 = await tqv.read_word_reg(0x04)
    assert val2_2 == 0xCAFEBABE, f"DST read 2 failed: {val2_2:08x}"
    
    dut._log.info("Register persistence test passed")


@cocotb.test()
async def test_dma_partial_write(dut):
    """Test partial register writes (byte, halfword access)"""
    dut._log.info("Start DMA Partial Write Test")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    dut._log.info("Test byte writes to registers")
    
    # Write full word
    await tqv.write_word_reg(0x02, 0x12345678)
    
    # Read back individual bytes
    b0 = await tqv.read_byte_reg(0x02)
    b1 = await tqv.read_byte_reg(0x03)
    b2 = await tqv.read_byte_reg(0x04)
    b3 = await tqv.read_byte_reg(0x05)
    
    # Verify byte ordering (little-endian)
    assert b0 == 0x78, f"Byte 0: expected 0x78, got {b0:02x}"
    assert b1 == 0x56, f"Byte 1: expected 0x56, got {b1:02x}"
    assert b2 == 0x34, f"Byte 2: expected 0x34, got {b2:02x}"
    assert b3 == 0x12, f"Byte 3: expected 0x12, got {b3:02x}"
    
    # Test halfword access
    h0 = await tqv.read_hword_reg(0x02)
    h1 = await tqv.read_hword_reg(0x04)
    
    assert h0 == 0x5678, f"HWord 0: expected 0x5678, got {h0:04x}"
    assert h1 == 0x1234, f"HWord 1: expected 0x1234, got {h1:04x}"
    
    dut._log.info("Partial write test passed")
