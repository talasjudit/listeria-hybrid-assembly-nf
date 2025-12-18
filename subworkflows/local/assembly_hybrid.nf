/*
========================================================================================
    ASSEMBLY_HYBRID Subworkflow
========================================================================================
    Hybrid genome assembly using Unicycler with optional Flye assembly input
    
    - Standard mode: Unicycler with short + long reads
    - Flye mode: Unicycler uses existing Flye assembly as scaffold

    Processes:
    - UNICYCLER: Hybrid assembly (handles both modes via optional assembly input)
========================================================================================
*/

// Import Unicycler process (handles optional Flye assembly)
include { UNICYCLER } from '../../modules/local/unicycler'

workflow ASSEMBLY_HYBRID {

    take:
    illumina_reads  // channel: tuple val(meta), path(reads) - [R1, R2]
    nanopore_reads  // channel: tuple val(meta), path(reads) - nanopore reads
    flye_assembly   // channel: tuple val(meta), path(assembly) - Flye assembly (or empty channel)

    main:
    // Combine all inputs by sample ID
    // Result: [meta, [R1, R2], nanopore, assembly_or_empty]
    ch_unicycler_input = illumina_reads
        .join(nanopore_reads, by: 0)
        .join(flye_assembly, by: 0, remainder: true)
        .map { meta, illumina, nanopore, assembly ->
            // If no Flye assembly, use empty list
            def asm = assembly ?: []
            [meta, illumina, nanopore, asm]
        }
    
    // Run Unicycler (handles both modes via optional assembly parameter)
    UNICYCLER(ch_unicycler_input)

    emit:
    assembly = UNICYCLER.out.assembly  // channel: tuple val(meta), path(assembly) - final assembly FASTA
    gfa      = UNICYCLER.out.gfa       // channel: tuple val(meta), path(gfa) - assembly graph
    logs     = UNICYCLER.out.process_log // channel: tuple val(meta), path(log) - assembly log
    versions = UNICYCLER.out.versions  // channel: path(versions.yml) - version info
}
