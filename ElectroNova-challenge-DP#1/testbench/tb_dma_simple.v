`timescale 1ns/1ps
`default_nettype none

module tb_dma_simple;
    reg clk = 0;
    reg rst_n = 0;
    integer i;

    // DMA peripheral register interface signals
    reg [5:0]  address;
    reg [31:0] data_in;
    reg [1:0]  data_write_n;
    reg [1:0]  data_read_n;
    wire [31:0] data_out;
    wire        data_ready;
    wire [7:0]  uo_out;
    wire        user_interrupt;

    // DMA master interface
    wire [31:0] m_rdata;
    reg         m_ready = 1'b1;
    reg         m_error = 1'b0;
    wire [31:0] m_addr;
    wire [31:0] m_wdata;
    wire [3:0]  m_wstrb;
    wire        m_write;
    wire        m_read;
    wire        m_valid;
    wire        idle;

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
        .idle(idle)
    );

    // Simple memory model
    reg [31:0] mem [0:255];
    
    // Combinatorial read (data available immediately)
    assign m_rdata = mem[m_addr[9:2]];

    // Write tracking
    always @(posedge clk) begin
        if (m_valid && m_write && m_ready) begin
            $display("DMA WRITE: addr=%h (idx=%d) data=%h", m_addr, m_addr[9:2], m_wdata);
            mem[m_addr[9:2]] <= m_wdata;
        end
    end

    // Clock
    always #5 clk = ~clk;

    initial begin
        // Initialize memory
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;
        mem[0] = 32'hDEADBEEF;
        mem[1] = 32'hCAFEBABE;
        mem[128] = 32'h11223344;  // 0x200
        mem[129] = 32'h55667788;  // 0x204

        // Reset
        rst_n = 0;
        data_write_n = 2'b11;
        data_read_n = 2'b11;
        address = 6'h00;
        data_in = 32'h0;
        #20;
        rst_n = 1;

        // Give time to initialize
        #100;

        // ===== TEST 1: Mem->Mem =====
        @(posedge clk);
        address = 6'h02; data_in = 32'h0; data_write_n = 2'b10; // SRC=0
        @(posedge clk) data_write_n = 2'b11;
        #100;

        @(posedge clk);
        address = 6'h04; data_in = 32'h100; data_write_n = 2'b10; // DST=0x100 (idx 0x40)
        @(posedge clk) data_write_n = 2'b11;
        #100;

        @(posedge clk);
        address = 6'h06; data_in = 32'h8; data_write_n = 2'b10; // LEN=8 bytes
        @(posedge clk) data_write_n = 2'b11;
        #100;

        @(posedge clk);
        address = 6'h00; data_in = 32'h1; data_write_n = 2'b10; // START
        @(posedge clk) data_write_n = 2'b11;

        #2000; // Wait for transfer

        // Check result
        if (mem[64] == 32'hDEADBEEF && mem[65] == 32'hCAFEBABE) begin
            $display("PASS: mem->mem transfer successful");
        end else begin
            $display("FAIL: mem->mem transfer failed. Got %h, %h", mem[64], mem[65]);
        end

        #100;
        $finish;
    end

endmodule

`default_nettype wire
