# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in Mux7to1De1.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns LevelVGADisplay.v

# Load simulation using RippleAdderDe1 as the top level simulation module.
vsim -L altera_mf_ver LevelVGADisplay

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}
add wave {/di/*}


force -repeat 20ns, {CLOCK_50} 0 0ns, 1 10ns
force {reset} 0;
force {level} 0100;
run 20ns

force {reset} 1;
run 10000ns