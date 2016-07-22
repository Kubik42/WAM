# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog ../Components/simple_number_tuner.v

# Load simulation using mux as the top level simulation module.
vsim tuner

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

# 2^16 given 0 between 0-8  -- > 0
force {num} 0
run 2 ns

# 2^16 given 330 between 0-8  --> 0
force {num} 101001010
run 2 ns

# 2^16 given 8191 between 0-8  --> 0
force {num} 1111111111111
run 2 ns

# 2^16 given 8192 between 0-8  --> 1
force {num} 10000000000000
run 2 ns

# 2^16 given 8193 between 0-8  --> 1
force {num} 10000000000001
run 2 ns

# 2^16 given 36405 between 0-8  --> 4
force {num} 1000111000110101
run 2 ns

# Given 65529 --> 8
force {num} 16'd65529
run 2 ns

# Given 65535 --> 8
force {num} 16'd65535
run 2 ns