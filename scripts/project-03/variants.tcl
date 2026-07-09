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
## Only one res/src/project-03/vivado_srcs/*.vhd file is ever the active
## top-level at synthesis time (`used_in_synthesis` true), per the
## project's manual top-level selection approach: a single .xpr, five
## separate top-level files, switched explicitly per build rather than via
## a VHDL generic. The simulation side mirrors this: one `configuration`
## per variant (declared in res/src/project-03/vivado_tbs/tb_top.vhd),
## switched explicitly via the sim fileset's `top` property, rather than
## via a testbench-side generic DUT selector.
## --------------------------------------------------------------------------

# variant_name -> {top_entity  vhd_file_relative_to_vivado_srcs  report_subfolder  sim_configuration  pipeline_latency}
array set ::VARIANTS {
    baseline               {top_baseline               top_baseline.vhd               baseline               0               2}
    registering            {top_registering            top_registering.vhd            registering            1               4}
    reordering             {top_reordering             top_reordering.vhd             reordering             2               2}
    reordering_registering {top_reordering_registering top_reordering_registering.vhd reordering_registering 3               4}
    isolated_reordering    {top_isolated_reordering    top_isolated_reordering.vhd    isolated_reordering    4               4}
}

## --------------------------------------------------------------------------
## select_variant: sets the given variant's top-level as the active
## synthesis top (excluding every other top-level file from synthesis),
## and sets the simulation fileset's top to the matching testbench
## configuration with the correct PIPELINE_LATENCY generic.
## --------------------------------------------------------------------------
proc select_variant {variant_name} {
    if {![info exists ::VARIANTS($variant_name)]} {
        error "Unknown variant '$variant_name'. Known variants: [array names ::VARIANTS]"
    }

    # Estrai variant_id al posto di sim_configuration
    lassign $::VARIANTS($variant_name) top_entity vhd_file report_subfolder variant_id pipeline_latency

    set synth_fileset [get_filesets sources_1]

    foreach {name entry} [array get ::VARIANTS] {
        lassign $entry entity_i file_i subfolder_i id_i latency_i
        set file_obj [get_files -of_objects $synth_fileset "*/vivado_srcs/$file_i"]
        if {[llength $file_obj] == 0} {
            continue
        }
        set_property used_in_synthesis [expr {$name eq $variant_name}] $file_obj
    }

    set_property top $top_entity $synth_fileset
    update_compile_order -fileset $synth_fileset

    if {[llength [get_filesets -quiet sim_1]] > 0} {
        set sim_fileset [get_filesets sim_1]

        # IL SIM TOP ORA E' FISSO A tb_top. Passiamo sia la latenza che l'ID della variante.
        set_property top tb_top $sim_fileset
        set_property generic "PIPELINE_LATENCY=$pipeline_latency VARIANT_ID=$variant_id" $sim_fileset
        update_compile_order -fileset $sim_fileset
    }

    puts "INFO: active variant = '$variant_name' (top = $top_entity, \
          sim_id = $variant_id @ latency=$pipeline_latency cycles, \
          reports -> reports/$report_subfolder)"

    return $::VARIANTS($variant_name)
}
