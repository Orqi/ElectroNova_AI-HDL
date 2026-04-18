`timescale 1ns/1ps

module tb_arbiter_proof;

    // 1. Mock CPU Signals (CPU is actively trying to fetch instructions)
    reg [27:0] cpu_addr    = 28'h1000000;
    reg [1:0]  cpu_write_n = 2'b11;
    reg [1:0]  cpu_read_n  = 2'b10; // Active low read
    wire       cpu_data_ready;

    // 2. Mock DMA Signals (DMA is currently idle)
    reg [31:0] dma_m_addr  = 32'h2000000;
    reg        dma_m_write = 0;
    reg [3:0]  dma_m_wstrb = 4'h0;
    reg        dma_m_read  = 0;
    reg        dma_m_valid = 0;

    // 3. The Shared Memory Bus (The Arbiter Output)
    wire [27:0] arb_addr;
    wire [1:0]  arb_write_n;
    wire [1:0]  arb_read_n;

    // Mock Memory Response
    reg data_ready = 1'b1; // Memory is always ready for this test

    // =================================================================
    // EXACT AI-HDL ARBITRATION LOGIC FROM project.v
    // =================================================================
    wire dma_active = dma_m_valid;

    // Map DMA AXI-style strobes to TinyQV active-low read/write semantics
    wire [1:0] dma_write_n = dma_m_write ? ((dma_m_wstrb == 4'hF) ? 2'b10 : (dma_m_wstrb >= 4'h3) ? 2'b01 : 2'b00) : 2'b11;
    wire [1:0] dma_read_n  = dma_m_read  ? 2'b10 : 2'b11;

    // Multiplex the physical bus wires
    assign arb_addr    = dma_active ? dma_m_addr[27:0] : cpu_addr;
    assign arb_write_n = dma_active ? dma_write_n      : cpu_write_n;
    assign arb_read_n  = dma_active ? dma_read_n       : cpu_read_n;

    // CPU Return Path (Stall CPU if DMA has taken the bus)
    wire cpu_req = (cpu_write_n != 2'b11) || (cpu_read_n != 2'b11);
    assign cpu_data_ready = dma_active ? (cpu_req ? 1'b0 : 1'b1) : data_ready;
    // =================================================================

    // 4. The Test Scenario
    initial begin
        $dumpfile("arbiter_proof.vcd");
        $dumpvars(0, tb_arbiter_proof);

        $display("-------------------------------------------------");
        $display("T=0ns: CPU owns the bus. DMA is idle.");
        #10;
        
        $display("T=10ns: DMA asserts m_valid for a burst write!");
        dma_m_valid = 1;
        dma_m_write = 1;
        dma_m_wstrb = 4'hF;
        #10;

        $display("T=20ns: DMA burst complete. Drops m_valid.");
        dma_m_valid = 0;
        dma_m_write = 0;
        #10;
        $display("-------------------------------------------------");

        $finish;
    end
endmodule