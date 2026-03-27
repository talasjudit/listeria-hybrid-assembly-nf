/*
========================================================================================
    ASSEMBLY_POLYPOLISH Subworkflow
========================================================================================
    Long-read assembly polished with Illumina reads: Flye → BWA MEM → Polypolish.

    This mode (--assembly_mode flye_polypolish) is suited for samples where Unicycler
    cannot circularise the chromosome due to high-copy-number repeats. Flye produces
    a circularised long-read assembly; Polypolish corrects base-level errors using
    the paired-end Illumina reads.

    Process:
    - BWA_MEM : index the Flye assembly and align R1/R2 independently (-a flag)
    - POLYPOLISH: filter suspicious pairs, then polish using alignment pile-ups

    BWA is run in a separate container (bwa-0.7.19.sif) because the Polypolish
    container does not include BWA.
========================================================================================
*/

include { BWA_MEM    } from '../../modules/local/bwa_mem'
include { POLYPOLISH } from '../../modules/local/polypolish'

workflow ASSEMBLY_POLYPOLISH {

    take:
    illumina_reads  // channel: tuple val(meta), path([R1, R2])
    flye_assembly   // channel: tuple val(meta), path(*_flye.fasta)

    main:
    ch_versions = Channel.empty()

    ch_bwa_input = flye_assembly
        .join(illumina_reads, by: 0)
        .map { meta, assembly, illumina -> [meta, assembly, illumina] }

    BWA_MEM(ch_bwa_input)
    ch_versions = ch_versions.mix(BWA_MEM.out.versions)

    POLYPOLISH(BWA_MEM.out.alignments)
    ch_versions = ch_versions.mix(POLYPOLISH.out.versions)

    emit:
    assembly = POLYPOLISH.out.assembly     // channel: tuple val(meta), path(*_polypolish.fasta)
    logs     = POLYPOLISH.out.process_log  // channel: tuple val(meta), path(*_polypolish.log)
    versions = ch_versions
}
