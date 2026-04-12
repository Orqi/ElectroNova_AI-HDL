`timescale 1ns/1ps
`default_nettype none

module tb_dma;
    reg clk = 0;
    reg rst_n = 0;

    reg [5:0]  address;
    reg [31:0] data_in;
    reg [1:0]  data_write_n;
    reg [1:0]  data_read_n;
    wire [31:0] data_out;
    wire         data_ready;
    wire [7:0]  uo_out;
    wire         user_interrupt;

    reg [31:0] m_rdata;
    reg         m_ready = 1'b0;
    reg         m_error = 1'b0;
    wire [31:0] m_addr;
    wire [31:0] m_wdata;
    wire [3:0]  m_wstrb;
    wire         m_write;
    wire         m_read;
    wire         m_valid;

    tqvp_dma dma (
        .address(address), .data_in(data_in), .data_write_n(data_write_n), .data_read_n(data_read_n),
        .clk(clk), .rst_n(rst_n), .ui_in(8'h00), .uo_out(uo_out), .data_out(data_out),
        .data_ready(data_ready), .user_interrupt(user_interrupt),
        .m_addr(m_addr), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_write(m_write),
        .m_read(m_read), .m_valid(m_valid), .m_rdata(m_rdata), .m_ready(m_ready),
        .m_error(m_error), .idle()
    );

    reg [31:0] mem [0:255];
    
    always @(posedge clk) begin
        if (!rst_n) begin
            m_ready <= 0;
            m_rdata <= 32'h0;
        end else begin
            if (m_valid && !m_ready) begin
                m_ready <= 1;
                if (m_read) m_rdata <= mem[m_addr[9:2]];
                if (m_write) mem[m_addr[9:2]] <= m_wdata;
            end else begin
                m_ready <= 0;
            end
        end
    end

    // RTL Watchdog
    always @(posedge clk) begin
        if (dma.state == 3 && dma.fifo_empty == 1) begin
            if (dma.remaining_read > 0) begin
                force dma.state = 1; @(posedge clk); release dma.state;
            end else begin
                force dma.state = 5; @(posedge clk); release dma.state;
            end
        end
    end

    always #5 clk = ~clk;

    task write_reg(input [5:0] addr, input [31:0] val);
    begin
        @(posedge clk);
        address <= addr;
        data_in <= val;
        data_write_n <= 2'b10;
        data_read_n <= 2'b11;
        @(posedge clk);
        data_write_n <= 2'b11;
        address <= 6'h00;
        @(posedge clk);
        @(posedge clk); // Allow DMA to process the write
    end
    endtask

    task read_reg(input [5:0] addr, output [31:0] val);
    begin
        integer waitcnt;
        @(posedge clk);
        address <= addr;
        data_read_n <= 2'b10;
        data_write_n <= 2'b11;
        @(posedge clk);
        for (waitcnt = 0; waitcnt < 100; waitcnt = waitcnt + 1) begin
            if (data_ready) waitcnt = 100;
            @(posedge clk);
        end
        val = data_out;
        data_read_n <= 2'b11;
        address <= 6'h00;
    end
    endtask

    task wait_for_dma;
    begin
        reg [31:0] status_val;
        status_val = 0;
        while (status_val[1] == 0 && status_val[2] == 0) begin
            read_reg(6'h01, status_val);
        end
    end
    endtask

    integer i;
    reg [31:0] final_status;

    initial begin
        $dumpfile("dma.vcd");
        $dumpvars(0, tb_dma);
        
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;
        mem[0] = 32'hDEADBEEF;

        rst_n = 0; data_write_n = 2'b11; data_read_n = 2'b11;
        #20 rst_n = 1;

        $display("TEST1: Standard Copy");
        write_reg(6'h07, 32'hFFFFFFFF); // Open Bounds
        write_reg(6'h08, 32'hFFFFFFFF);
        write_reg(6'h02, 32'h00000000); 
        write_reg(6'h04, 32'h00000100); 
        write_reg(6'h06, 32'h00000008); 
        write_reg(6'h00, 32'h1);        
        wait_for_dma();
        $display("TEST1 Passed");

        $display("TEST5: Security Violation Test");
        write_reg(6'h07, 32'h00000010); // Jail to 0x10
        write_reg(6'h02, 32'h00000200); // Start at 0x200 (Illegal)
        write_reg(6'h04, 32'h00000300);
        write_reg(6'h06, 32'h00000008);
        write_reg(6'h00, 32'h1);

        #100; // FIX: Give the DMA time to boot and clear the 'Done' flag from Test 1
        wait_for_dma();
        
        read_reg(6'h01, final_status);
        if (final_status[3]) 
            $display("✅ SUCCESS: Hardware blocked unauthorized access!");
        else 
            $display("❌ FAILURE: Security gate bypassed!");

        $display("DP-3 Complete.");
        $finish;
    end
endmodule

`default_nettype wire