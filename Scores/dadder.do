# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in Mux7to1De1.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns DecimalModules.v

# Load simulation using RippleAdderDe1 as the top level simulation module.
vsim DecimalAdder4Dig

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}


force {A} 0000_0000_0000_0000
force {B} 0000_0000_0000_0000
#Reset state
run 20ns

force {A} 0001_0010_0100_1000
force {B} 0000_0000_0000_0000
#Reset state
run 20ns

force {B} 0001_0010_0100_1000
force {A} 0000_0000_0000_0000
#Reset state
run 20ns

force {A} 1001_1001_0100_1000
force {B} 0001_0000_0000_0000
#Reset state
run 20ns

force {A} 0101_1001_0101_0111
force {B} 0110_1000_1001_0001
run 20ns