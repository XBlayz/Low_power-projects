## --------------------------------------------------------------------------
## run_variant.tcl, project-03
##
## Runs the full synthesis -> implementation -> post-implementation timing
## simulation (SAIF activity dump) -> report export flow for a single
## architectural variant, at a given clock period.
##
## Usage:
##   vivado -mode batch -source scripts/project-03/run_variant.tcl \
##       -tclargs <variant_name> [clk_period_ns] [dut_instance_path]
##
## Examples:
##   vivado -mode batch -source scripts/project-03/run_variant.tcl -tclargs baseline
##   vivado -mode batch -source scripts/project-03/run_variant.tcl -tclargs registering 10.0
##   vivado -mode batch -source scripts/project-03/run_variant.tcl -tclargs reordering 5.5
##
## Recommended invocation (captures the console/simulation log for the
## Python notebook's STEP 1 functional-check parsing):
##   vivado -mode batch \
##       -log notebooks/output/project-03/sims/reports/<variant>/vivado_console_<clk_period_ns>ns.log \
##       -source scripts/project-03/run_variant.tcl -tclargs <variant> <clk_period_ns>
##
## Outputs (under notebooks/output/project-03/sims/reports/<variant>/):
##   utilization.rpt, timing_summary.rpt, power.rpt, activity.saif
##
## ASSUMPTIONS (flagged pending STEP 1 / testbench deliverable):
##   - res/src/project-03/vivado_tbs/tb_top.vhd exists (entity tb_top,
##     architecture sim) and self-terminates the simulation (VHDL-2008
##     std.env.stop), so `run -all` completes without an explicit
##     sim_time argument.
##   - the DUT is instantiated in tb_top under instance name `dut`. The
##     active simulation top is a `configuration` (cfg_baseline,
##     cfg_registering, ...), set per variant by select_variant; xsim's
##     reported hierarchy path for `dut` may be rooted at the
##     configuration name rather than at `tb_top` depending on tool
##     behavior. dut_instance_path defaults to `/tb_top/dut`; verify the
##     actual path in the first simulation run's waveform/log and override
##     via the third tclarg if it differs (e.g. `/cfg_baseline/dut`).
## --------------------------------------------------------------------------

# --- Arguments --------------------------------------------------------------
if {[llength $argv] < 1} {
    error "Usage: run_variant.tcl <variant_name> \[clk_period_ns\] \[dut_instance_path\]"
}
lassign $argv variant_name clk_period_ns dut_instance_path

if {$clk_period_ns eq ""} { set clk_period_ns 10.0 }
if {$dut_instance_path eq ""} { set dut_instance_path "/tb_top/dut" }

# --- Paths --------------------------------------------------------------
# This script lives at <repo_root>/scripts/project-03/, two levels below
# the repo root.
set script_dir [file normalize [file dirname [info script]]]
set repo_root  [file normalize [file join $script_dir ".." ".."]]

set sims_dir     [file join $repo_root "notebooks" "output" "project-03" "sims"]
set project_root [file join $sims_dir "vivado_project"]
set reports_root [file join $sims_dir "reports"]
set xpr_path      [file join $project_root "project-03.xpr"]

source [file join $script_dir "variants.tcl"]

# --- Open (or bootstrap) the project ---------------------------------------
if {[file exists $xpr_path]} {
    open_project $xpr_path
} else {
    puts "INFO: project-03.xpr not found, bootstrapping via create_project.tcl"
    source [file join $script_dir "create_project.tcl"]
}

# --- Select variant and clock period ----------------------------------------
set variant_info [select_variant $variant_name]
lassign $variant_info top_entity vhd_file report_subfolder sim_configuration pipeline_latency

set ::clk_period_ns $clk_period_ns
puts "INFO: clk_period_ns = $::clk_period_ns"

set reports_dir [file join $reports_root $report_subfolder]
file mkdir $reports_dir

# --- Helper: abort on run failure --------------------------------------------
proc check_run_status {run_name} {
    set status [get_property STATUS [get_runs $run_name]]
    if {[string match -nocase "*error*" $status] || [string match -nocase "*failed*" $status]} {
        error "$run_name failed (status: $status). Check the run log before re-running."
    }
    puts "INFO: $run_name completed (status: $status)"
}

# --- Synthesis --------------------------------------------------------------
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
check_run_status synth_1

# --- Implementation -----------------------------------------------------
reset_run impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1
check_run_status impl_1

open_run impl_1

# --- Utilization and timing reports (from the implemented design) -----------
report_utilization    -file [file join $reports_dir "utilization.rpt"]
report_timing_summary -file [file join $reports_dir "timing_summary.rpt"] -max_paths 10

# --- Post-implementation timing simulation: SAIF activity dump --------------
set saif_path [file join $reports_dir "activity.saif"]

launch_simulation -mode post-implementation -type timing -simset [get_filesets sim_1]

open_saif $saif_path
log_saif [get_objects -r "${dut_instance_path}/*"]
run -all
close_saif

close_sim

# --- Power report, using the post-implementation activity dump --------------
open_run impl_1
report_power -file [file join $reports_dir "power.rpt"] \
              -saif $saif_path \
              -saif_scope $dut_instance_path

puts "INFO: variant '$variant_name' @ ${clk_period_ns}ns done. \
      Reports written to $reports_dir"
