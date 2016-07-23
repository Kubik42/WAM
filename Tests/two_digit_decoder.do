# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog two_digit_decoder.v 

# Load simulation using top level simulation module.
vsim two_digit_decoder

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force {reset} 0
run 5ns

force {reset} 1
# 10
force {b} 001010
run 5ns

# 21
force {b} 010101
run 5ns

# 60
force {b} 111100
run 5ns

# 63
force {b} 111111
run 5ns
