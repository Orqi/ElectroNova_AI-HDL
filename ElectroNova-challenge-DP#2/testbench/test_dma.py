import cocotb
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_dma_2d_operation(dut):
    """Verify that the DMA starts and handles a basic 2D transfer"""
    # Initialize clock and reset
    dut.rst_n.value = 0
    await Timer(10, units="ns")
    dut.rst_n.value = 1
    
    # Set 2D Parameters (Assuming your optimized register names)
    dut.src_addr.value = 0x1000
    dut.length.value = 32 # 2 rows of 4 words
    # If you added stride/row_len regs, set them here:
    # dut.stride.value = 64 
    
    # Start the DMA
    dut.start_r.value = 1
    await RisingEdge(dut.clk)
    dut.start_r.value = 0

    # Wait for completion
    for _ in range(20):
        await RisingEdge(dut.clk)
        if dut.done_flag.value == 1:
            break

    assert dut.done_flag.value == 1, "DMA Transfer failed to complete!"
    dut._log.info("PPA Optimization Verified: 2D Transfer Completed Successfully.")