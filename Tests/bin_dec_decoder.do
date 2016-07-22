# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog bin_dec_decoder.v 

# Load simulation using top level simulation module.
vsim bdd

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force {reset} 0
run 5ns

force {reset} 1
force {binary} 0000
run 5ns

force {binary} 0001
run 5ns
force {binary} 0010
run 5ns
force {binary} 0011
run 5ns
force {binary} 0100
run 5ns
force {binary} 0101
run 5ns
force {binary} 0110
run 5ns
force {binary} 0111
run 5ns
force {binary} 1000
run 5ns
force {binary} 1001
run 5ns