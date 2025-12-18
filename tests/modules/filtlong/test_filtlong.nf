#!/usr/bin/env nextflow
/*
========================================================================================
    FILTLONG Module Unit Test
========================================================================================
    Usage: nextflow run tests/modules/filtlong/test_filtlong.nf -c nextflow.config -profile singularity,slurm
========================================================================================
*/

nextflow.enable.dsl=2

// Import module to test
include { FILTLONG } from '../../../modules/local/filtlong'

workflow {

    log.info """
    ╔═══════════════════════════════════════════════════════════════╗
    ║                 FILTLONG-Module Test                          ║
    ╚═══════════════════════════════════════════════════════════════╝

    Testing FILTLONG module with test data...
    """.stripIndent()

    // Create metadata for test sample
    def meta = [
        id: 'test_sample',
        single_end: true
    ]

    // Define test data path
    def test_reads = file("${launchDir}/tests/data/test_nanopore.fastq.gz")

    // Check test data exists
    if (!test_reads.exists()) {
        log.error "Test data not found!"
        log.error "Expected file: ${test_reads}"
        log.error ""
        log.error "Please add test data to tests/data/"
        exit 1
    }

    log.info "Test data found:"
    log.info "  - Nanopore: ${test_reads.name} (${test_reads.size()} bytes)"
    log.info ""

    // Create input channel
    ch_input = Channel.of([meta, test_reads])

    // Run FILTLONG
    FILTLONG(ch_input)

    // Verify outputs
    FILTLONG.out.reads
        .view { m, reads ->
            log.info "✓ Filtered reads: ${reads.name} (${reads.size()} bytes)"
        }

    FILTLONG.out.log
        .view { m, logfile ->
            log.info "✓ Log file: ${logfile.name} (${logfile.size()} bytes)"
        }

    FILTLONG.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    log.info ""
    log.info "═══════════════════════════════════════════════════════════════"
    if (workflow.success) {
        log.info "FILTLONG module test completed successfully!"
    } else {
        log.info "FILTLONG module test failed!"
    }
    log.info "═══════════════════════════════════════════════════════════════"
    log.info ""
}