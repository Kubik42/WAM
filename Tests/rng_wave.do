# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog ../random_number_generator.v

# Load simulation using mux as the top level simulation module.
vsim rng

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}


# 50 MHz clock
force {clk} 0 0, 1 1 -r 2

# Resetting
force {reset} 0
run 2 ns

# Loading seed
force {seed} 0
force {seed[0]} 1
force {reset} 1
force {load} 1
run 2 ns

# Generating numbers
force {load} 0
run 320 ns
