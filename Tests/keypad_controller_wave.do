# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog ../Controller/keypad_controller.v

# Load simulation using mux as the top level simulation module.
vsim keypad_controller

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}


# 50 MHz clock
force {clk} 0 0, 1 1 -r 2

# Resetting
force {clear} 0
run 2 ns 

force {clear} 1

# No rows
force {row} 3'b111
run 10000 ns

# Key 1
force {row} 3'b110
run 2000 ns

force {row} 3'b111
run 2000 ns

# Key 4
force {row} 3'b101
run 5500 ns

force {row} 3'b111
run 2000 ns

# Key 7
force {row} 3'b011
run 10000 ns

force {row} 3'b111
run 2000 ns

# More than one button press
force {row} 3'b100
run 10000 ns
