`timescale 1ns/1ps
`default_nettype none

module tb_dma;
    // Signals
    reg clk = 0;
    reg rst_n = 0;
    reg [5:0] address = 0;
    reg [31:0] data_in = 0;
    reg [1:0] data_write_n = 2'b11;
    reg [1:0] data_read_n = 2'b11;
    wire [31:0] data_out;
    wire data_ready, user_interrupt, idle;

    reg [31:0] m_rdata = 0;
    reg m_ready = 0;
    wire [31:0] m_addr;
    wire [31:0] m_wdata;
    wire m_read, m_write, m_valid;

    tqvp_dma dma (
        .address(address), .data_in(data_in), .data_write_n(data_write_n), .data_read_n(data_read_n),
        .clk(clk), .rst_n(rst_n), .ui_in(8'h00), .uo_out(), .data_out(data_out),
        .data_ready(data_ready), .user_interrupt(user_interrupt),
        .m_addr(m_addr), .m_wdata(m_wdata), .m_wstrb(), .m_rdata(m_rdata), .m_ready(m_ready),
        .m_read(m_read), .m_write(m_write), .m_valid(m_valid), .m_error(1'b0), .idle(idle)
    );

    always #5 clk = ~clk;

    // Memory Mock
    always @(posedge clk) begin
        if (!rst_n) m_ready <= 0;
        else if (m_valid && !m_ready) begin
            m_ready <= 1;
            m_rdata <= 32'hDA7A0000 | m_addr[15:0];
        end else m_ready <= 0;
    end

    // Bus Monitor
    integer read_count = 0;
    integer write_count = 0;
    always @(posedge clk) begin
        if (m_valid && m_read && m_ready) $display("  READ  #%0d addr=0x%08h", ++read_count, m_addr);
        if (m_valid && m_write && m_ready) $display("  WRITE #%0d addr=0x%08h", ++write_count, m_addr);
    end

    task write_reg(input [5:0] addr, input [31:0] val);
    begin
        @(negedge clk);
        address = addr; data_in = val; data_write_n = 2'b10;
        @(negedge clk);
        data_write_n = 2'b11;
        repeat(1) @(posedge clk);
    end
    endtask

    task wait_for_idle;
        integer i;
    begin
        repeat(5) @(posedge clk);
        for (i = 0; i < 500 && !idle; i = i + 1) @(posedge clk);
    end
    endtask

    initial begin
        $dumpfile("tb_dma.vcd");
        $dumpvars(0, tb_dma);

        // Reset
        rst_n = 0; #40 rst_n = 1; repeat(5) @(posedge clk);

        // --- TEST 1: 2D Stride ---
        $display("\nTEST 1: 2D Stride AI Mode");
        read_count = 0; write_count = 0;
        write_reg(6'h07, 32'hFFFFFFFF); // Bounds
        write_reg(6'h08, 32'hFFFFFFFF);
        write_reg(6'h02, 32'h00001000); // SRC
        write_reg(6'h03, 32'h00000100); // STRIDE
        write_reg(6'h04, 32'h00002000); // DST
        write_reg(6'h05, 32'h00000008); // ROW: 8 bytes
        write_reg(6'h06, 32'h00000010); // LEN: 16 bytes
        write_reg(6'h00, 32'h11);       // START 2D
        wait_for_idle;
        write_reg(6'h00, 0);            // Clear Control
        $display("TEST 1 Complete. Reads: %0d", read_count);

        // --- SOFT RESET ---
        rst_n = 0; #20 rst_n = 1; repeat(5) @(posedge clk);

        // --- TEST 2: 1D Linear ---
        $display("\nTEST 2: 1D Linear Regression");
        read_count = 0; write_count = 0;
        write_reg(6'h07, 32'hFFFFFFFF);
        write_reg(6'h08, 32'hFFFFFFFF);
        write_reg(6'h02, 32'h00003000); // SRC
        write_reg(6'h04, 32'h00004000); // DST
        write_reg(6'h06, 32'h00000010); // LEN: 16 bytes
        write_reg(6'h00, 32'h01);       // START 1D
        wait_for_idle;
        $display("TEST 2 Complete. Reads: %0d", read_count);

        $display("\nALL TESTS FINISHED");
        $finish;
    end
endmodule