# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in Mux7to1De1.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns MoleRL.v

# Load simulation using RippleAdderDe1 as the top level simulation module.
vsim testRL

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}
add wave {/mrlfsm/curr_state}


force -repeat 20ns, {CLOCK_50} 0 0ns, 1 10ns
force -repeat 20ns, {CLOCK_WAIT} 0 0ns, 1 10ns
force -repeat 20ns, {CLOCK_RL} 0 0ns, 1 10ns
force {go} 0;
force {reset} 1;
#Reset state
run 20ns

force {reset} 0;
run 20ns 

force {go} 1;
run 20ns;

force {go} 0;
run 1000ns;

force {go} 1;
run 200 ns;

force {reset} 1;
run 20 ns;
