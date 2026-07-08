## --------------------------------------------------------------------------
## run_all.tcl, project-03
##
## Sweeps every registered variant (see variants.tcl) across the two clock
## campaigns (standard / high-performance), for the STEP 8 cross-
## configuration comparison. Each (variant, clock period) combination is
## run in its own, isolated `vivado -mode batch` subprocess (via `exec`),
## to avoid stale run/simulation state leaking between combinations within
## a single long-lived Vivado Tcl session.
##
## Usage (run from an OS shell with `vivado` on PATH, NOT from within an
## interactive Vivado Tcl console):
##   vivado -mode batch -source scripts/project-03/run_all.tcl
##
## A run failing does not abort the sweep: it is logged and the next
## combination is attempted, so a single bad variant does not block the
## rest of the comparison.
## --------------------------------------------------------------------------

# This script lives at <repo_root>/scripts/project-03/, two levels below
# the repo root.
set script_dir [file normalize [file dirname [info script]]]
set repo_root  [file normalize [file join $script_dir ".." ".."]]

source [file join $script_dir "variants.tcl"]

# --- Clock campaigns ------------------------------------------------------
# STANDARD_CLK_NS matches the reference PDF's baseline campaign (10ns).
# HIGH_PERF_CLK_NS is a placeholder: tighten it once the target part is
# known and a realistic overconstraint value has been chosen (Table 2.6 in
# the reference PDF uses per-variant fmax figures around 130-200MHz).
set STANDARD_CLK_NS  10.0
set HIGH_PERF_CLK_NS 6.0

set clock_campaigns [list $STANDARD_CLK_NS $HIGH_PERF_CLK_NS]

set run_variant_script [file join $script_dir "run_variant.tcl"]
set reports_root       [file join $repo_root "notebooks" "output" "project-03" "sims" "reports"]

set failures {}

foreach variant_name [array names ::VARIANTS] {
    lassign $::VARIANTS($variant_name) top_entity vhd_file report_subfolder sim_configuration pipeline_latency
    set reports_dir [file join $reports_root $report_subfolder]
    file mkdir $reports_dir

    foreach clk_period_ns $clock_campaigns {
        set console_log [file join $reports_dir "vivado_console_${clk_period_ns}ns.log"]

        puts "\n===================================================================="
        puts "INFO: running variant='$variant_name'  clk_period_ns=$clk_period_ns"
        puts "console log -> $console_log"
        puts "====================================================================\n"

        set exit_status [catch {
            exec vivado -mode batch -log $console_log -source $run_variant_script \
                -tclargs $variant_name $clk_period_ns \
                >&@stdout
        } result]

        if {$exit_status != 0} {
            puts "WARNING: run failed for variant='$variant_name' clk_period_ns=$clk_period_ns : $result"
            lappend failures "$variant_name @ ${clk_period_ns}ns"
        }
    }
}

puts "\n===================================================================="
if {[llength $failures] == 0} {
    puts "INFO: run_all.tcl completed, all combinations succeeded."
} else {
    puts "WARNING: run_all.tcl completed with [llength $failures] failed combination(s):"
    foreach f $failures { puts "  - $f" }
}
puts "====================================================================\n"
