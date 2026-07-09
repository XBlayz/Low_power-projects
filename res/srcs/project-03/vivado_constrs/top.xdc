## --------------------------------------------------------------------------
## Clock constraint, project-03
##
## `clk_period_ns` is a Tcl variable, not an XDC parameter: XDC files are
## evaluated in the same Tcl interpreter as the running Vivado session, so a
## global variable set before synthesis/implementation is picked up here.
## Defaults to 10ns (reference clock constraint, Pitingolo PDF) when the
## variable has not been set by the calling script (e.g. opening the project
## interactively in the GUI).
##
## No physical I/O (PACKAGE_PIN / IOSTANDARD) constraints are defined yet:
## the target part/board is still TBD, and none are required for synthesis,
## implementation, or power/timing report generation without bitstream
## generation. Add them here once a target board is chosen and hardware
## bring-up / bitstream generation is needed.
## --------------------------------------------------------------------------
create_clock -period 10.0 -name clk [get_ports clk]
