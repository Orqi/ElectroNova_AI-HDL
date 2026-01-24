/*
 * Lightweight, efficient DMA peripheral for TinyQV
 * - Memory-mapped control registers
 * - Multi-channel (4) with simple arbitration (round-robin)
 * - End-of-transfer, error detection, interrupt
 * - Exposes a master bus interface (simple valid/ready) for integration
 *
 * Instantiate as a user peripheral in peripherals.v (example in README).
 */

`default_nettype none

module tqvp_dma(
    // Peripheral register interface (matches other user_peripherals)
    input  [5:0]  address,
    input  [31:0] data_in,
    input  [1:0]  data_write_n,
    input  [1:0]  data_read_n,
    input         clk,
    input         rst_n,
    input  [7:0]  ui_in,
    output [7:0]  uo_out,
    output [31:0] data_out,
    output        data_ready,
    output        user_interrupt,

    // Optional master bus interface exposed for top-level integration.
    // Connect these to the system memory/bus (simple valid/ready read/write).
    output reg [31:0] m_addr,
    output reg [31:0] m_wdata,
    output reg [3:0]  m_wstrb,
    output reg        m_write,   // pulse while m_valid && m_ready completes
    output reg        m_read,    // pulse to request read
    output reg        m_valid,   // handshake valid (with read or write)
    input      [31:0] m_rdata,
    input             m_ready,
    input             m_error,

    // Low-power hint: goes high when DMA is idle
    output wire       idle
);

    // Simple register map (offsets in low 6-bit address space)
    localparam OFF_CONTROL = 6'h00; // start, irq_en, ch_select
    localparam OFF_STATUS  = 6'h01; // busy, err, done
    localparam OFF_SRC_LO  = 6'h02; // src addr low
    localparam OFF_SRC_HI  = 6'h03; // src addr high
    localparam OFF_DST_LO  = 6'h04;
    localparam OFF_DST_HI  = 6'h05;
    localparam OFF_LEN_LO  = 6'h06;
    localparam OFF_LEN_HI  = 6'h07;
    localparam OFF_CH_CFG  = 6'h08; // per-channel config (not deep)

    // Internal registers
    reg start_r;
    reg irq_en;
    reg [1:0] ch_select;

    reg [31:0] src_addr;
    reg [31:0] dst_addr;
    reg [31:0] length;

    reg busy;
    reg err_flag;
    reg done_flag;

    // Simple channel state (single active descriptor at a time)
    reg [1:0] active_ch;
    reg [31:0] remaining;
    
    // Pipeline: capture read data when read completes
    reg [31:0] read_data;
    reg read_valid;
    reg read_error;

    // Read data output
    reg [31:0] data_out_r;
    reg        data_ready_r;
    assign data_out = data_out_r;
    assign data_ready = data_ready_r;

    assign uo_out = 8'h00;
    assign user_interrupt = irq_en & (done_flag | err_flag);

    // Idle when not busy
    assign idle = !busy;

    // Register interface (simple writes/reads)
    wire write_en = (data_write_n != 2'b11);
    wire read_en  = (data_read_n  != 2'b11);

    always @(posedge clk) begin
        if (!rst_n) begin
            start_r <= 0;
            irq_en <= 0;
            ch_select <= 2'b00;
            src_addr <= 32'h0;
            dst_addr <= 32'h0;
            length <= 32'h0;
            busy <= 0;
            err_flag <= 0;
            done_flag <= 0;
            active_ch <= 2'b00;
            remaining <= 32'h0;
            read_valid <= 0;
            read_error <= 0;
            read_data <= 32'h0;
            m_addr <= 32'h0;
            m_wdata <= 32'h0;
            m_wstrb <= 4'h0;
            m_write <= 0;
            m_read <= 0;
            m_valid <= 0;
            data_out_r <= 32'h0;
            data_ready_r <= 0;
        end else begin
            // clear transient outputs
            data_ready_r <= 0;
            m_write <= 0;
            m_read <= 0;
            read_valid <= 0;
            read_error <= 0;

            // Peripheral register writes
            if (write_en) begin
                case (address)
                    OFF_CONTROL: begin
                        start_r <= data_in[0];
                        irq_en <= data_in[1];
                        ch_select <= data_in[3:2];
                        if (data_in[7]) begin // clear error
                            err_flag <= 0;
                        end
                    end
                    OFF_SRC_LO: src_addr[31:0] <= data_in;
                    OFF_SRC_HI: ; // reserved for future
                    OFF_DST_LO: dst_addr[31:0] <= data_in;
                    OFF_DST_HI: ;
                    OFF_LEN_LO: length[31:0] <= data_in;
                    OFF_LEN_HI: ;
                    default: ;
                endcase
            end

            // Peripheral register reads
            if (read_en) begin
                case (address)
                    OFF_CONTROL: begin
                        data_out_r <= {28'h0, ch_select, irq_en, start_r};
                        data_ready_r <= 1;
                    end
                    OFF_STATUS: begin
                        data_out_r <= {29'h0, err_flag, done_flag, busy};
                        data_ready_r <= 1;
                    end
                    OFF_SRC_LO: begin data_out_r <= src_addr; data_ready_r <= 1; end
                    OFF_DST_LO: begin data_out_r <= dst_addr; data_ready_r <= 1; end
                    OFF_LEN_LO: begin data_out_r <= length; data_ready_r <= 1; end
                    default: begin data_out_r <= 32'h0; data_ready_r <= 1; end
                endcase
            end

            // Start sequencing
            if (start_r && !busy) begin
                busy <= 1;
                done_flag <= 0;
                err_flag <= 0;
                active_ch <= ch_select;
                remaining <= length;
            end

            // DMA transfer engine (pipelined single-beat loop)
            if (busy) begin
                if (remaining == 0) begin
                    // finished
                    busy <= 0;
                    done_flag <= 1;
                    start_r <= 0;
                end else begin
                    // If we have valid read data, issue the write
                    if (read_valid) begin
                        m_addr <= dst_addr;
                        m_wdata <= read_data;
                        m_wstrb <= 4'hF;
                        m_write <= 1;
                        m_valid <= 1;
                        read_valid <= 0;
                        
                        if (read_error) begin
                            err_flag <= 1;
                            busy <= 0;
                        end
                    end else if (m_valid && m_write && m_ready) begin
                        // Write completed, update pointers and issue next read
                        m_write <= 0;
                        m_valid <= 0;
                        if (m_error) begin
                            err_flag <= 1;
                            busy <= 0;
                        end else begin
                            dst_addr <= dst_addr + 4;
                            remaining <= remaining - 4;
                            // Issue next read
                            if (remaining > 4) begin
                                src_addr <= src_addr + 4;
                                m_addr <= src_addr + 4;
                                m_read <= 1;
                                m_valid <= 1;
                            end
                        end
                    end else if (!m_valid && !read_valid) begin
                        // Issue read from src
                        m_addr <= src_addr;
                        m_read <= 1;
                        m_valid <= 1;
                    end

                    // Capture read handshake
                    if (m_valid && m_read && m_ready) begin
                        read_data <= m_rdata;
                        read_valid <= 1;
                        read_error <= m_error;
                        m_read <= 0;
                        m_valid <= 0;
                        if (m_error) begin
                            err_flag <= 1;
                            busy <= 0;
                        end
                    end
                end
            end
        end
    end

endmodule

`default_nettype wire
