# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog ../wam.v

# Load simulation using mux as the top level simulation module.
vsim wam

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}


# 50 MHz clock
force {CLOCK_50} 0 0, 1 1 -r 2

# Setting difficulty
force {KEY[0]} 1
force {SW[3:0]} 4'b0001

# Setting points
force {SW[5]} 0

# Setting game mode
force {SW[9:7]} 100

# Input
force {key_matrix_row} 111

run 10 ns

# Starting game
force {KEY[0]} 0
run 2 ns

force {KEY[0]} 1
run 12000 ns

# Starting new game
force {KEY[0]} 0
run 2 ns

force {KEY[0]} 1
run 12000 ns

# Setting game mode: Timed
force {SW[9:7]} 010
force {KEY[0]} 0
run 2 ns

force {KEY[0]} 1
run 5000 ns

# Starting new game
force {KEY[0]} 0
run 2 ns

force {KEY[0]} 1
run 5000 ns

# Setting game mode: Lives
force {SW[9:7]} 001

# Increasing life count to 3
force {KEY[1]} 1
run 2 ns

force {KEY[1]} 0
run 2 ns

force {KEY[1]} 1
run 2 ns

force {KEY[1]} 0
run 2 ns

force {KEY[1]} 1
run 2 ns

force {KEY[1]} 0
run 2 ns

force {KEY[0]} 0
run 10 ns

force {KEY[0]} 1
run 5000 ns
