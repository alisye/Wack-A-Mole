# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in Mux7to1De1.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns TotalScore.v

# Load simulation using RippleAdderDe1 as the top level simulation module.
vsim CompleteCount

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force -repeat 20ns, {clock} 0 0ns, 1 10ns
force -repeat 40ns, {clockrL} 0 0ns, 1 20ns
force -repeat 80ns, {clock_wait} 0 0ns, 1 40ns
force {reset_moles} 1;
force {reset_scores} 1;
force {control} 00000000;
force {mole_hit} 00000000;
run 20ns

force {reset_moles} 0;
force {reset_scores} 0;
run 60ns 

force {control} 10000000;
run 20ns 

force {control} 00000000;
run 5000ns

force {control} 00001000;
run 100ns;

force {mole_hit} 00001000;
run 20ns;

force {mole_hit} 00000000;
run 100ns;