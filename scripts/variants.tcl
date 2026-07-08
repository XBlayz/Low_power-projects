## --------------------------------------------------------------------------
## Variant registry, project-03
##
## Single source of truth mapping each architectural variant to its
## top-level VHDL entity/file, report output subfolder, testbench
## configuration, and expected pipeline latency (in clock cycles, from
## input capture to Z valid -- used by tb_top.vhd's latency-agnostic
## self-checking reference pipeline). Sourced by create_project.tcl (to add
## all top_*.vhd files as sources) and by run_variant.tcl (to select the
## active top-level and simulation configuration for a given build).
##
## Only one src/top/*.vhd file is ever the active top-level at synthesis
## time (`used_in_synthesis` true), per the project's manual top-level
## selection approach: a single .xpr, five separate top-level files,
## switched explicitly per build rather than via a VHDL generic. The
## simulation side mirrors this: one `configuration` per variant (declared
## in tb/tb_top.vhd), switched explicitly via the sim fileset's `top`
## property, rather than via a testbench-side generic DUT selector.
## --------------------------------------------------------------------------

# variant_name -> {top_entity  vhd_file_relative_to_src/top  report_subfolder  sim_configuration  pipeline_latency}
array set ::VARIANTS {
    baseline               {top_baseline               top_baseline.vhd               baseline               cfg_baseline               2}
    registering             {top_registering            top_registering.vhd            registering             cfg_registering             4}
    reordering              {top_reordering             top_reordering.vhd             reordering              cfg_reordering              2}
    reordering_registering  {top_reordering_registering top_reordering_registering.vhd reordering_registering  cfg_reordering_registering  4}
    isolated_reordering     {top_isolated_reordering    top_isolated_reordering.vhd    isolated_reordering     cfg_isolated_reordering     4}
}
# NOTE: `razor` (STEP 7, optional extension) is intentionally not registered
# yet: its top-level source and razor_reg entity do not exist until that
# extension is implemented. Add an entry here when it is.

## --------------------------------------------------------------------------
## select_variant: sets the given variant's top-level as the active
## synthesis top (excluding every other top_*.vhd from synthesis), and sets
## the simulation fileset's top to the matching testbench configuration
## with the correct PIPELINE_LATENCY generic.
## --------------------------------------------------------------------------
proc select_variant {variant_name} {
    if {![info exists ::VARIANTS($variant_name)]} {
        error "Unknown variant '$variant_name'. Known variants: [array names ::VARIANTS]"
    }

    lassign $::VARIANTS($variant_name) top_entity vhd_file report_subfolder sim_configuration pipeline_latency

    set synth_fileset [get_filesets sources_1]

    # Disable every top-level file from synthesis, then re-enable only the
    # one belonging to the selected variant.
    foreach {name entry} [array get ::VARIANTS] {
        lassign $entry entity_i file_i subfolder_i config_i latency_i
        set file_obj [get_files -of_objects $synth_fileset "*/src/top/$file_i"]
        if {[llength $file_obj] == 0} {
            puts "WARNING: source file for variant '$name' not found ($file_i); skipping."
            continue
        }
        set_property used_in_synthesis [expr {$name eq $variant_name}] $file_obj
    }

    set_property top $top_entity $synth_fileset
    update_compile_order -fileset $synth_fileset

    # Simulation fileset: select the matching configuration and latency.
    if {[llength [get_filesets -quiet sim_1]] > 0} {
        set sim_fileset [get_filesets sim_1]
        set_property top $sim_configuration $sim_fileset
        set_property generic "PIPELINE_LATENCY=$pipeline_latency" $sim_fileset
        update_compile_order -fileset $sim_fileset
    }

    puts "INFO: active variant = '$variant_name' (top = $top_entity, \
          sim = $sim_configuration @ latency=$pipeline_latency cycles, \
          reports -> reports/$report_subfolder)"

    return $::VARIANTS($variant_name)
}
