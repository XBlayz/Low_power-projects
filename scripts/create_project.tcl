## --------------------------------------------------------------------------
## create_project.tcl, project-03
##
## One-time project bootstrap. Creates the Vivado project (project-03.xpr,
## not committed to version control, see .gitignore) directly in this
## folder, adds every shared and top-level VHDL source, the testbench, and
## the constraints file, then selects the Baseline variant as the initial
## active top-level.
##
## Usage:
##   vivado -mode batch -source tcl/create_project.tcl
##
## Re-run safely: if project-03.xpr already exists, the script opens it
## instead of recreating it.
## --------------------------------------------------------------------------

set ::PART_NAME "xc7z020clg484-3"

# --- Paths, resolved relative to this script's own location ---------------
set script_dir   [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $script_dir ".."]]
set src_dir       [file join $project_root "src"]
set top_dir       [file join $src_dir "top"]
set tb_dir        [file join $project_root "tb"]
set constraints_dir [file join $project_root "constraints"]

source [file join $script_dir "variants.tcl"]

set xpr_path [file join $project_root "project-03.xpr"]

if {[file exists $xpr_path]} {
    puts "INFO: project-03.xpr already exists, opening it."
    open_project $xpr_path
} else {
    if {$::PART_NAME eq "TBD"} {
        puts "WARNING: PART_NAME is not set yet (see TODO above). \
              Using a generic Artix-7 part as a placeholder; \
              re-run create_project.tcl after setting the real target part."
        set ::PART_NAME "xc7a35tcpg236-1"
    }

    create_project project-03 $project_root -part $::PART_NAME -force

    # --- Shared entities (used by every variant) ---------------------------
    add_files -norecurse -fileset sources_1 [glob -directory $src_dir "*.vhd"]

    # --- Top-level variants (all added, only one active at a time) --------
    foreach {variant_name entry} [array get ::VARIANTS] {
        lassign $entry top_entity vhd_file report_subfolder
        set top_path [file join $top_dir $vhd_file]
        if {[file exists $top_path]} {
            add_files -norecurse -fileset sources_1 $top_path
        } else {
            puts "WARNING: top-level source for '$variant_name' not found ($top_path); \
                  add it later and re-run create_project.tcl, or add_files manually."
        }
    }

    # --- Testbench (Behavioral and Post-implementation simulation) --------
    # NOTE: tb_top.vhd declares 5 configurations (one per variant, see
    # variants.tcl); which one is the active sim top is set by
    # select_variant, not hardcoded here. Requires VHDL-2008 (std.env.stop,
    # to_hstring).
    set tb_path [file join $tb_dir "tb_top.vhd"]
    if {[file exists $tb_path]} {
        add_files -norecurse -fileset sim_1 $tb_path
        set_property FILE_TYPE {VHDL 2008} [get_files $tb_path]
    } else {
        puts "WARNING: testbench not found ($tb_path); simulation fileset left empty."
    }

    # --- Constraints ---------------------------------------------------------
    add_files -norecurse -fileset constrs_1 [file join $constraints_dir "top.xdc"]

    update_compile_order -fileset sources_1

    # --- Default active variant ---------------------------------------------
    select_variant baseline

    save_project_as project-03 $project_root -force
}

puts "INFO: project-03 ready at $xpr_path"
