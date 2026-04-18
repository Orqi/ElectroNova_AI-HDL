`default_nettype none

module tqvp_dma(
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

    // Master bus interface
    output reg [31:0] m_addr,
    output reg [31:0] m_wdata,
    output reg [3:0]  m_wstrb,
    output reg        m_write,
    output reg        m_read,
    output reg        m_valid,
    input      [31:0] m_rdata,
    input             m_ready,
    input             m_error,

    output wire       idle
);

    localparam OFF_CONTROL    = 6'h00;
    localparam OFF_STATUS     = 6'h01;
    localparam OFF_SRC_LO     = 6'h02;
    localparam OFF_SRC_STRIDE = 6'h03;
    localparam OFF_DST_LO     = 6'h04;
    localparam OFF_ROW_SIZE   = 6'h05;
    localparam OFF_LEN_LO     = 6'h06;
    localparam OFF_SRC_BOUND  = 6'h07;
    localparam OFF_DST_BOUND  = 6'h08;

    reg irq_en, mode_2d;
    reg [31:0] src_addr, dst_addr, length, src_stride, row_size;
    reg [31:0] src_bound, dst_bound;

    // start_r: set by SW writing bit0 of CONTROL, cleared when DMA launches.
    // This makes it a one-shot pulse — writing 1 starts one transfer, not a loop.
    reg start_r;

    // Read-side 2D row tracking
    reg [31:0] words_in_row;
    // Latched at launch so SW writes mid-transfer can't corrupt a live run
    reg [31:0] src_stride_lat, row_size_lat;

    reg busy, err_flag, done_flag, sec_violation;
    reg [31:0] remaining_read, remaining_write;
    reg [1:0]  burst_count;

    localparam IDLE=0, FETCH_READ=1, WAIT_READ=2, ISSUE_WRITE=3, WAIT_WRITE=4, DONE=5;
    reg [2:0] state;

    // Pipelined FIFO (4 entries)
    reg [31:0] fifo [0:3];
    reg [1:0]  fifo_head, fifo_tail;
    reg [2:0]  fifo_count;
    wire fifo_full  = (fifo_count == 3'd4);
    wire fifo_empty = (fifo_count == 3'd0);
    wire fifo_push  = (state == WAIT_READ && m_valid && m_read && m_ready && !m_error);

    // Bounds checking
    wire is_reading = (state == FETCH_READ || state == WAIT_READ);
    wire is_writing = (state == ISSUE_WRITE || state == WAIT_WRITE);
    wire addr_fault = busy && (
                        (is_reading && (src_addr > src_bound)) ||
                        (is_writing && (dst_addr > dst_bound))
                      );

    reg [31:0] data_out_r;
    reg        data_ready_r;
    assign data_out       = data_out_r;
    assign data_ready     = data_ready_r;
    assign uo_out         = 8'h00;
    assign user_interrupt = irq_en & (done_flag | err_flag | sec_violation);
    assign idle           = !busy;

    always @(posedge clk) begin
        if (!rst_n) begin
            {start_r, irq_en, mode_2d}                 <= 3'b0;
            {src_addr, dst_addr, length}                <= 96'h0;
            {src_stride, row_size}                      <= 64'h0;
            {src_stride_lat, row_size_lat}              <= 64'h0;
            words_in_row                                <= 0;
            src_bound                                   <= 32'hFFFFFFFF;
            dst_bound                                   <= 32'hFFFFFFFF;
            {busy, err_flag, done_flag, sec_violation}  <= 4'b0;
            state      <= IDLE;
            fifo_count <= 0; fifo_head <= 0; fifo_tail <= 0;
            m_valid <= 0; m_write <= 0; m_read <= 0;
            m_addr  <= 0; m_wdata <= 0; m_wstrb <= 0;
            data_out_r   <= 32'h0;
            data_ready_r <= 0;
        end else begin
            data_ready_r <= 0;

            // ----------------------------------------------------------------
            // Register writes
            // Gated by !busy so SW can't clobber config mid-transfer.
            // Exception: reading STATUS/CONTROL while busy is always allowed.
            // ----------------------------------------------------------------
            if (data_write_n != 2'b11 && !busy) begin
                case (address)
                    OFF_CONTROL: begin
                        // Writing bit0=1 arms the start trigger.
                        // Writing bit0=0 de-arms it (cancel before launch).
                        // done_flag is cleared whenever SW re-arms start,
                        // so a second transfer can be started after the first.
                        start_r  <= data_in[0];
                        irq_en   <= data_in[1];
                        mode_2d  <= data_in[4];
                        if (data_in[0]) done_flag <= 0; // re-arm clears done
                    end
                    OFF_SRC_LO:     src_addr   <= data_in;
                    OFF_SRC_STRIDE: src_stride <= data_in;
                    OFF_DST_LO:     dst_addr   <= data_in;
                    OFF_ROW_SIZE:   row_size   <= data_in;
                    OFF_LEN_LO:     length     <= data_in;
                    OFF_SRC_BOUND:  src_bound  <= data_in;
                    OFF_DST_BOUND:  dst_bound  <= data_in;
                endcase
            end

            // ----------------------------------------------------------------
            // Register reads
            // ----------------------------------------------------------------
            if (data_read_n != 2'b11) begin
                data_ready_r <= 1;
                case (address)
                    OFF_CONTROL:   data_out_r <= {27'h0, mode_2d, 2'b00, irq_en, start_r};
                    OFF_STATUS:    data_out_r <= {28'h0, sec_violation, err_flag, done_flag, busy};
                    OFF_SRC_LO:    data_out_r <= src_addr;
                    OFF_SRC_BOUND: data_out_r <= src_bound;
                    OFF_DST_BOUND: data_out_r <= dst_bound;
                    default:       data_out_r <= 32'h0;
                endcase
            end

            // ----------------------------------------------------------------
            // FIFO push on successful read beat
            // ----------------------------------------------------------------
            if (fifo_push) begin
                fifo[fifo_tail] <= m_rdata;
                fifo_tail       <= fifo_tail + 1;
                fifo_count      <= fifo_count + 1;
            end

            // ----------------------------------------------------------------
            // Launch condition:
            //   start_r=1  — SW has armed the trigger
            //   !busy      — no transfer in progress
            //
            // start_r is cleared HERE at launch (one-shot).
            // This prevents the FSM re-launching itself when DONE clears busy,
            // because start_r is already 0 by the time busy goes low.
            // ----------------------------------------------------------------
            if (start_r && !busy) begin
                start_r         <= 0;           // consume the trigger
                state           <= FETCH_READ;
                busy            <= 1;
                err_flag        <= 0;
                sec_violation   <= 0;
                remaining_read  <= length;
                remaining_write <= length;
                words_in_row    <= 0;
                burst_count     <= 0;
                fifo_count      <= 0;
                fifo_head       <= 0;
                fifo_tail       <= 0;
                src_stride_lat  <= src_stride;
                row_size_lat    <= row_size;
            end

            // ----------------------------------------------------------------
            // FSM — only runs while busy
            // ----------------------------------------------------------------
            if (busy) begin
                if (addr_fault) begin
                    state         <= DONE;
                    err_flag      <= 1;
                    sec_violation <= 1;
                    m_valid <= 0; m_read <= 0; m_write <= 0;
                end else begin
                    case (state)

                        FETCH_READ: begin
                            if (!fifo_full && remaining_read != 0) begin
                                m_addr  <= src_addr;
                                m_read  <= 1;
                                m_valid <= 1;
                                state   <= WAIT_READ;
                            end else if (!fifo_empty) begin
                                state <= ISSUE_WRITE;
                            end else if (remaining_read == 0) begin
                                state <= DONE;
                            end
                        end

                        // ----------------------------------------------------
                        // 2D stride is tracked HERE on the read side.
                        // src_addr is updated the same cycle the read completes
                        // so the next FETCH_READ issues the correct address.
                        // ----------------------------------------------------
                        WAIT_READ: begin
                            if (m_valid && m_read && m_ready) begin
                                m_valid        <= 0;
                                m_read         <= 0;
                                remaining_read <= (remaining_read > 4) ? remaining_read - 4 : 0;
                                burst_count    <= burst_count + 1;

                                if (m_error) begin
                                    err_flag <= 1;
                                    state    <= DONE;
                                end else begin
                                    if (mode_2d) begin
                                        if (words_in_row + 4 >= row_size_lat) begin
                                            // Row complete: stride-jump to next row start
                                            // next_base = src_addr - words_in_row + src_stride_lat
                                            src_addr     <= src_addr - words_in_row + src_stride_lat;
                                            words_in_row <= 0;
                                        end else begin
                                            src_addr     <= src_addr + 4;
                                            words_in_row <= words_in_row + 4;
                                        end
                                    end else begin
                                        src_addr <= src_addr + 4;
                                    end

                                    state <= (!fifo_full && remaining_read > 4 && burst_count != 3)
                                             ? FETCH_READ : ISSUE_WRITE;
                                end
                            end
                        end

                        ISSUE_WRITE: begin
                            if (!fifo_empty) begin
                                m_addr  <= dst_addr;
                                m_wdata <= fifo[fifo_head];
                                m_wstrb <= (remaining_write >= 4) ? 4'hF :
                                           (remaining_write == 3) ? 4'h7 :
                                           (remaining_write == 2) ? 4'h3 : 4'h1;
                                m_write <= 1;
                                m_valid <= 1;
                                state   <= WAIT_WRITE;
                            end
                        end

                        // ----------------------------------------------------
                        // WAIT_WRITE: advances dst_addr only.
                        // src_addr is NOT touched here.
                        // ----------------------------------------------------
                        WAIT_WRITE: begin
                            if (m_valid && m_write && m_ready) begin
                                m_valid         <= 0;
                                m_write         <= 0;
                                fifo_head       <= fifo_head + 1;
                                fifo_count      <= fifo_count - 1;
                                dst_addr        <= dst_addr + 4;
                                remaining_write <= (remaining_write > 4) ? remaining_write - 4 : 0;

                                if (m_error) begin
                                    err_flag <= 1;
                                    state    <= DONE;
                                end else begin
                                    state <= (!fifo_empty)         ? ISSUE_WRITE :
                                             (remaining_read != 0) ? FETCH_READ  : DONE;
                                end
                            end
                        end

                        // ----------------------------------------------------
                        // DONE: set done_flag, release busy, return to IDLE.
                        // start_r was already cleared at launch so the FSM
                        // cannot re-launch itself here.
                        // ----------------------------------------------------
                        DONE: begin
                            done_flag <= 1;
                            busy      <= 0;
                            state     <= IDLE;
                        end

                    endcase
                end
            end
        end
    end
endmodule

`default_nettype wire