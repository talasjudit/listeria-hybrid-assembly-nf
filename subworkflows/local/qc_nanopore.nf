/*
========================================================================================
    QC_NANOPORE Subworkflow
========================================================================================
    Quality control for Nanopore reads: adapter trimming + quality filtering

    Purpose:
    - Groups two processes that always run together in sequence
    - Adapter removal with Porechop ABI
    - Quality filtering with Filtlong
    - Collects logs and versions from both steps

    Processes:
    1. PORECHOP_ABI - Removes adapters from Nanopore reads
    2. FILTLONG - Filters reads by quality and length
========================================================================================
*/

// Import required processes
include { PORECHOP_ABI } from '../../modules/local/porechop_abi'
include { FILTLONG } from '../../modules/local/filtlong'

workflow QC_NANOPORE {

    take:
    reads  // channel: tuple val(meta), path(reads) - raw Nanopore reads

    main:
    PORECHOP_ABI(reads)
    FILTLONG(PORECHOP_ABI.out.reads)

    ch_reads = FILTLONG.out.reads
    ch_logs = PORECHOP_ABI.out.log
        .mix(FILTLONG.out.log)
    ch_versions = PORECHOP_ABI.out.versions
        .mix(FILTLONG.out.versions)

    emit:
    reads    = ch_reads     // channel: tuple val(meta), path(reads) - QC'd Nanopore reads
    logs     = ch_logs      // channel: path(log) - all log files
    versions = ch_versions  // channel: path(versions.yml) - all version files
}

