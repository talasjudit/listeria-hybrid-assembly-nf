#!/usr/bin/env nextflow
/*
========================================================================================
    PORECHOP_ABI Module Unit Test
========================================================================================
    Usage: nextflow run tests/modules/porechop_abi/test_porechop_abi.nf -c nextflow.config -profile singularity,slurm
========================================================================================
*/

nextflow.enable.dsl=2

// Import module to test
include { PORECHOP_ABI } from '../../../modules/local/porechop_abi'

workflow {

    log.info """
    ╔═══════════════════════════════════════════════════════════════╗
    ║              PORECHOP_ABI Module Test                         ║
    ╚═══════════════════════════════════════════════════════════════╝

    Testing PORECHOP_ABI module with test data...
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

    // Run PORECHOP_ABI
    PORECHOP_ABI(ch_input)

    // Verify outputs
    PORECHOP_ABI.out.reads
        .view { m, reads ->
            log.info "✓ Trimmed reads: ${reads.name} (${reads.size()} bytes)"
        }

    PORECHOP_ABI.out.log
        .view { m, logfile ->
            log.info "✓ Log file: ${logfile.name} (${logfile.size()} bytes)"
        }

    PORECHOP_ABI.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    log.info ""
    log.info "═══════════════════════════════════════════════════════════════"
    if (workflow.success) {
        log.info "PORECHOP_ABI module test completed successfully!"
    } else {
        log.info "PORECHOP_ABI module test failed!"
    }
    log.info "═══════════════════════════════════════════════════════════════"
    log.info ""
}