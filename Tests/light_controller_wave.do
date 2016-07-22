# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog ../Controller/light_controller.v

# Load simulation using mux as the top level simulation module.
vsim light_controller

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}


# 50 MHz clock
force {clk} 0 0, 1 1 -r 2

# Loading seed
force {time_on} 28'd99
force {time_between} 28'd99
force {load_seed} 1
run 2 ns

# Resetting
force {reset} 0
force {load_seed} 0
run 2 ns

# Generating numbers
force {reset} 1
force {start} 1
run 5000 ns
