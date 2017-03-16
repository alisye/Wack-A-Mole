# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in Mux7to1De1.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns rand.v

# Load simulation using RippleAdderDe1 as the top level simulation module.
vsim controlSeq

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force -repeat 20ns, {clock} 0 0ns, 1 10ns

force {reset} 1
force {shift} 0
force {load_val} 1
#Reset state
run 20ns

force {reset} 0
run 40ns 

force {shift} 1 
run 60ns

force {load_val} 0
run 60ns 

force {shift} 0 
run 60ns

force {reset} 1
run 20ns