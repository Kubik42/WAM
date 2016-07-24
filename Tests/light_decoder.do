# Set the working dir, where all compiled Verilog goes.
vlib work
# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog light_decoder.v 

# Load simulation using top level simulation module.
vsim light_decoder

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force {in} 0000
run 5ns
force {in} 0001
run 5ns
force {in} 0010
run 5ns
force {in} 0011
run 5ns
force {in} 0100
run 5ns
force {in} 0101
run 5ns
force {in} 0110
run 5ns
force {in} 0111
run 5ns
force {in} 1000
run 5ns