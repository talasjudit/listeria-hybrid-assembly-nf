/*
========================================================================================
    QC_ASSEMBLY Subworkflow
========================================================================================
    Assembly quality assessment using CheckM2 and QUAST

    Purpose:
    - Groups two processes that always run together
    - CheckM2 assesses completeness and contamination
    - QUAST provides assembly statistics (N50, contig counts, etc.)
    - Both processes run in parallel on the same assembly

    Processes (run in parallel):
    1. CHECKM2 - Completeness and contamination assessment
    2. QUAST - Assembly statistics and quality metrics

========================================================================================
*/

// Import required processes
include { CHECKM2 } from '../../modules/local/checkm2'
include { QUAST } from '../../modules/local/quast'

workflow QC_ASSEMBLY {

    take:
    assemblies  // channel: tuple val(meta), path(assembly) - genome assemblies

    main:
    // Run CheckM2 and QUAST in parallel (both receive same input)
    CHECKM2(assemblies)
    QUAST(assemblies)

    // Collect reports
    ch_checkm2_reports = CHECKM2.out.report
    ch_quast_reports = QUAST.out.report

    // Collect logs from both tools
    ch_logs = CHECKM2.out.log
        .mix(QUAST.out.log)

    // Collect versions from both tools
    ch_versions = CHECKM2.out.versions
        .mix(QUAST.out.versions)

    emit:
    checkm2_reports = ch_checkm2_reports  // channel: tuple val(meta), path(report) - CheckM2 TSV reports
    quast_reports   = ch_quast_reports    // channel: tuple val(meta), path(report) - QUAST TSV reports
    quast_dir       = QUAST.out.dir       // channel: tuple val(meta), path(dir) - QUAST output directory
    quast_html      = QUAST.out.html      // channel: tuple val(meta), path(html) - QUAST HTML reports
    quast_icarus    = QUAST.out.icarus    // channel: tuple val(meta), path(icarus) - QUAST Icarus viewer
    logs            = ch_logs             // channel: tuple val(meta), path(log) - all log files
    versions        = ch_versions         // channel: path(versions.yml) - version files
}
