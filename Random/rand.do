# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in Mux7to1De1.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns rand.v

# Load simulation using RippleAdderDe1 as the top level simulation module.
vsim rand_module

# Log all signals and add some signals to waveform window.
log {/*}
log {/lfsr/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force -repeat 20ns, {CLOCK_50} 0 0ns, 1 10ns
force -repeat 40ns, {CLOCK_1Hz} 0 0ns, 1 20ns

force {Rreset} 1
force {Rload_lfsr} 0
force {Rshift} 0
force {Rspeed} 0
#Reset state
run 20ns

force {Rreset} 0
run 60ns 

force {Rload_lfsr} 1 
force {Rspeed} 1
run 20ns

force {Rload_lfsr} 0
force {Rshift} 1
run 5000ns 

force {Rshift} 0 
force {Rspeed} 0
run 40ns
