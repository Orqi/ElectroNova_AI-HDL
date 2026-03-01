module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/tqvp_dma.fst");
    $dumpvars(0, tqvp_dma);
end
endmodule
