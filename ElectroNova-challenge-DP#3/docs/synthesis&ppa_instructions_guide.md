# Run tqvp_dma using OpenLane (Docker)

# 1. Start container
docker run -it -v $HOME:/openlane -v $HOME/.volare:/home/openlane/.volare efabless/openlane:latest

# 2. Inside container
cd /openlane/designs/new_tqvp_dma

# 3. Setup PDK (first time only)
volare fetch bdc9412b3e468c102d01b7cf6337be06ec6e9c9a sky130A
volare enable bdc9412b3e468c102d01b7cf6337be06ec6e9c9a

# 4. Run flow
rm -rf runs
flow.tcl -design .


Synthesize with Yosys and Generate a Report
# This command assumes you are in the root of the ElectroNova_AI-HDL project.
yosys -p "read_verilog src/user_peripherals/tqvp_dma.v; hierarchy -check -top tqvp_dma; synth_ice40 -top tqvp_dma; stat"