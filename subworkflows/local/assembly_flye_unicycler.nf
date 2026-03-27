/*
========================================================================================
    ASSEMBLY_FLYE_UNICYCLER Subworkflow
========================================================================================
    Two-step assembly: Flye long-read assembly used as a scaffold for Unicycler.

    This mode (--assembly_mode flye_unicycler) is suited for samples where complex
    repeat structures prevent standard Unicycler from circularising the chromosome.
    Flye resolves the repeats with long reads alone; Unicycler then polishes and
    scaffolds using the Illumina short reads.

    Process:
    - UNICYCLER: hybrid assembly with --existing_long_read_assembly (Flye FASTA)
      (Flye itself is run in the main workflow before this subworkflow is called)
========================================================================================
*/

include { UNICYCLER } from '../../modules/local/unicycler'

workflow ASSEMBLY_FLYE_UNICYCLER {

    take:
    illumina_reads  // channel: tuple val(meta), path([R1, R2])
    nanopore_reads  // channel: tuple val(meta), path(reads)
    flye_assembly   // channel: tuple val(meta), path(*_flye.fasta)

    main:
    ch_unicycler_input = illumina_reads
        .join(nanopore_reads, by: 0)
        .join(flye_assembly, by: 0)
        .map { meta, illumina, nanopore, assembly -> [meta, illumina, nanopore, assembly] }
        // assembly passed to Unicycler via --existing_long_read_assembly

    UNICYCLER(ch_unicycler_input)

    emit:
    assembly = UNICYCLER.out.assembly      // channel: tuple val(meta), path(*_unicycler.fasta)
    gfa      = UNICYCLER.out.gfa           // channel: tuple val(meta), path(*_unicycler_graph.gfa)
    logs     = UNICYCLER.out.process_log   // channel: tuple val(meta), path(*.log)
    versions = UNICYCLER.out.versions      // channel: path(versions.yml)
}
