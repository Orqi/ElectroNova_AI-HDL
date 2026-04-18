**test instructions**
cd test

**for security tb**

iverilog -g2009 -o security.vvp tb_dma_security.v ../src/user_peripherals/tqvp_dma.v
vvp security.vvp
gtkwave dma_security.vcd

**for 2D stride test tb**

iverilog -g2009 -o stride.vvp tb_dma_stride.v ../src/user_peripherals/tqvp_dma.v
vvp stride.vvp
gtkwave tb_dma.vcd

**for arbiter proof**

iverilog -g2009 -o arbiter_proof.vvp tb_arbiter_proof.v ../src/user_peripherals/tqvp_dma.v
vvp arbiter_proof.vvp
gtkwave arbiter_proof.vcd