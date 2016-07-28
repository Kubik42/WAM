# Set the working dir, where all compiled Verilog goes.
vlib work
# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog ../Components/one_min_count.v 

# Load simulation using top level simulation module.
vsim one_min_count

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force {clk} 0 0, 1 1 -r 2

force {reset} 0
run 5ns

force {reset} 1
force {start_game} 1
run 40000000ns