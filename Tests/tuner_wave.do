# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog ../number_tuner.v

# Load simulation using mux as the top level simulation module.
vsim tuner

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

# 2^16 given 0 between 0-8  -- > 0
force {power} 10000
force {number} 0
force {min} 0
force {max} 1000
run 2 ns

# 2^16 given 330 between 0-8  --> 0
force {number} 101001010
run 2 ns

# 2^16 given 8191 between 0-8  --> 0
force {number} 1111111111111
run 2 ns

# 2^16 given 8192 between 0-8  --> 1
force {number} 10000000000000
run 2 ns

# 2^16 given 8193 between 0-8  --> 1
force {number} 10000000000001
run 2 ns

# 2^16 given 36405 between 0-8  --> 4
force {number} 1000111000110101
run 2 ns

# 2^16 given 36405 between 8-22  --> 15
force {min} 1000
force {max} 10110
force {number} 1000111000110101
run 2 ns

# 2^8 given 132 between 8-22  --> 15
force {power} 1000
force {min} 1000
force {max} 10110
force {number} 10000100
run 2 ns

# 2^8 given 256 between 8-22  --> 22
force {number} 100000000
run 2 ns

# 2^8 given 8 between 8-22  --> 8
force {number} 1000
run 2 ns

# 2^8 given 257 between 8-22  --> error --> 0
force {number} 100000001
run 2 ns

