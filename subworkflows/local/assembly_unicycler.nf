/*
========================================================================================
    ASSEMBLY_UNICYCLER Subworkflow
========================================================================================
    Standard hybrid assembly: Unicycler with Illumina short reads + Nanopore long reads.

    This is the default assembly mode (--assembly_mode unicycler).
    Unicycler builds a short-read assembly graph and uses Nanopore reads to bridge
    and resolve repeats.

    Process:
    - UNICYCLER: hybrid assembly (no existing long-read assembly)
========================================================================================
*/

include { UNICYCLER } from '../../modules/local/unicycler'

workflow ASSEMBLY_UNICYCLER {

    take:
    illumina_reads  // channel: tuple val(meta), path([R1, R2])
    nanopore_reads  // channel: tuple val(meta), path(reads)

    main:
    ch_unicycler_input = illumina_reads
        .join(nanopore_reads, by: 0)
        .map { meta, illumina, nanopore -> [meta, illumina, nanopore, []] }
        // empty list [] = no existing assembly → standard hybrid mode

    UNICYCLER(ch_unicycler_input)

    emit:
    assembly = UNICYCLER.out.assembly      // channel: tuple val(meta), path(*_unicycler.fasta)
    gfa      = UNICYCLER.out.gfa           // channel: tuple val(meta), path(*_unicycler_graph.gfa)
    logs     = UNICYCLER.out.process_log   // channel: tuple val(meta), path(*.log)
    versions = UNICYCLER.out.versions      // channel: path(versions.yml)
}
