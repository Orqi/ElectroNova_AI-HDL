`timescale 1ns/1ps
`default_nettype none

module tb_dma;
    reg clk = 0;
    reg rst_n = 0;

    // DMA peripheral register interface signals
    reg [5:0]  address;
    reg [31:0] data_in;
    reg [1:0]  data_write_n;
    reg [1:0]  data_read_n;
    wire [31:0] data_out;
    wire        data_ready;
    wire [7:0]  uo_out;
    wire        user_interrupt;

    // DMA master interface (connect to memory model below)
    wire [31:0] m_rdata;
    reg          m_ready = 1'b1;
    reg          m_error = 1'b0;
    wire [31:0] m_addr;
    wire [31:0] m_wdata;
    wire [3:0]  m_wstrb;
    wire        m_write;
    wire        m_read;
    wire        m_valid;

    // Instantiate DMA
    tqvp_dma dma (
        .address(address),
        .data_in(data_in),
        .data_write_n(data_write_n),
        .data_read_n(data_read_n),
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(8'h00),
        .uo_out(uo_out),
        .data_out(data_out),
        .data_ready(data_ready),
        .user_interrupt(user_interrupt),
        .m_addr(m_addr),
        .m_wdata(m_wdata),
        .m_wstrb(m_wstrb),
        .m_write(m_write),
        .m_read(m_read),
        .m_valid(m_valid),
        .m_rdata(m_rdata),
        .m_ready(m_ready),
        .m_error(m_error),
        .idle()
    );

    // Simple memory model: 1 KiB words (32-bit) at byte-addressed offsets
    reg [31:0] mem [0:255];

    // Drive m_rdata combinatorially for immediate access
    assign m_rdata = mem[m_addr[9:2]];

    // Monitor write requests from DMA and apply to mem
    always @(posedge clk) begin
        if (m_valid && m_write && m_ready) begin
            // Use address /4 as word index (aligned)
            mem[m_addr[9:2]] <= m_wdata;
        end
    end

    // Clock
    always #5 clk = ~clk;

    // Utility tasks to write/read DMA registers using the peripheral register interface
    task write_reg(input [5:0] addr, input [31:0] value);
    begin
        @(posedge clk);
        address <= addr;
        data_in <= value;
        data_write_n <= 2'b10; // 32-bit
        data_read_n <= 2'b11;
        @(posedge clk);
        // deassert
        data_write_n <= 2'b11;
        data_in <= 32'h0;
        address <= 6'h00;
    end
    endtask

    task read_reg(input [5:0] addr, output [31:0] value);
    begin
        integer waitcnt;
        @(posedge clk);
        address <= addr;
        data_read_n <= 2'b10; // 32-bit
        data_write_n <= 2'b11;
        @(posedge clk);
        // Wait for data_ready
        for (waitcnt = 0; waitcnt < 100; waitcnt = waitcnt + 1) begin
            if (data_ready) waitcnt = 100;
            @(posedge clk);
        end
        value = data_out;
        data_read_n <= 2'b11;
        address <= 6'h00;
    end
    endtask

    integer i, j;
    reg [31:0] val;
    integer outfile;

    initial begin
        // --- Added waveform dump commands ---
        $dumpfile("dma.vcd");
        $dumpvars(0, tb_dma);
        // ------------------------------------

        outfile = $fopen("dma_test.log", "w");
        $fwrite(outfile, "=== DMA Testbench Start ===\n");
        $fflush(outfile);
        // initialise memory
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;

        // Put some test data at 0x000 and 0x004
        mem[0] = 32'hDEADBEEF;
        mem[1] = 32'hCAFEBABE;

        // Put peripheral-like data region at 0x200/0x204 (byte addr 0x200 -> index 0x80)
        mem[8'h80] = 32'h11223344;
        mem[8'h81] = 32'h55667788;

        // Reset
        rst_n = 0;
        data_write_n = 2'b11;
        data_read_n = 2'b11;
        address = 6'h00;
        data_in = 32'h0;
        #20;
        rst_n = 1;

        // Test 1: Memory-to-memory copy: src=0x0, dst=0x100, len=8
        $fwrite(outfile, "TEST1: mem->mem copy\n");
        $fflush(outfile);
        write_reg(6'h02, 32'h00000000); // SRC_LO
        write_reg(6'h04, 32'h00000100); // DST_LO
        write_reg(6'h06, 32'h00000008); // LEN_LO (bytes)
        write_reg(6'h00, 32'h1);         // CONTROL: start

        // Poll status until done
        val = 0;
        repeat (1000) begin
            read_reg(6'h01, val);
            if (val[1]) begin
                $display("DMA done (mem->mem)");
            end
            if (val[2]) begin
                $display("DMA error");
            end
            if (val[1] || val[2]) begin
                // exit wait loop
            end
        end

        // Check contents at dst (word indices 0x100/4 = 0x40)
        if (mem[8'h40] !== 32'hDEADBEEF) $display("ERROR: dst[0] mismatch: %08x", mem[8'h40]);
        if (mem[8'h41] !== 32'hCAFEBABE) $display("ERROR: dst[1] mismatch: %08x", mem[8'h41]);
        $display("mem->mem verification passed");

        // Test 2: Peripheral-to-memory: src=0x200 (peripheral region), dst=0x120, len=8
        $display("TEST2: peri->mem copy");
        write_reg(6'h02, 32'h00000200);
        write_reg(6'h04, 32'h00000120);
        write_reg(6'h06, 32'h00000008);
        write_reg(6'h00, 32'h1);

        // Poll
        val = 0;
        repeat (1000) begin
            read_reg(6'h01, val);
            if (val[1]) $display("DMA done (peri->mem)");
            if (val[2]) $display("DMA error");
        end

        if (mem[8'h48] !== 32'h11223344) $display("ERROR: peri->mem dst[0] mismatch: %08x", mem[8'h48]);
        if (mem[8'h49] !== 32'h55667788) $display("ERROR: peri->mem dst[1] mismatch: %08x", mem[8'h49]);
        $display("peri->mem verification passed");

        // Test 3: Peripheral-to-peripheral: src=0x200 -> dst=0x300, len=8
        $display("TEST3: peri->peri copy");
        write_reg(6'h02, 32'h00000200);
        write_reg(6'h04, 32'h00000300);
        write_reg(6'h06, 32'h00000008);
        write_reg(6'h00, 32'h1);

        val = 0;
        repeat (1000) begin
            read_reg(6'h01, val);
            if (val[1]) $display("DMA done (peri->peri)");
            if (val[2]) $display("DMA error");
        end

        if (mem[8'hC0] !== 32'h11223344) $display("ERROR: peri->peri dst[0] mismatch: %08x", mem[8'hC0]);
        if (mem[8'hC1] !== 32'h55667788) $display("ERROR: peri->peri dst[1] mismatch: %08x", mem[8'hC1]);
        $display("peri->peri verification passed");

        $display("All tests completed");
        $finish;
    end

endmodule

`default_nettype wire