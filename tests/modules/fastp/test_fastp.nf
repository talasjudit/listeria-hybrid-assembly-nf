#!/usr/bin/env nextflow
/*
========================================================================================
    FASTP Module Unit Test
========================================================================================
    Usage: nextflow run tests/modules/fastp/test_fastp.nf -c nextflow.config -profile singularity,slurm
========================================================================================
*/

nextflow.enable.dsl=2

// Import module to test
include { FASTP } from '../../../modules/local/fastp'

workflow {

    log.info """
    ╔═══════════════════════════════════════════════════════════════╗
    ║                  FASTP Module Test                            ║
    ╚═══════════════════════════════════════════════════════════════╝

    Testing FASTP module with test data...
    """.stripIndent()

    // Create metadata for test sample
    def meta = [
        id: 'test_sample',
        single_end: false
    ]

    // Define test data paths - look in tests/data/ directory
    def test_r1 = file("${launchDir}/tests/data/test_R1.fastq.gz")
    def test_r2 = file("${launchDir}/tests/data/test_R2.fastq.gz")

    // Check test data exists
    if (!test_r1.exists() || !test_r2.exists()) {
        log.error "Test data not found!"
        log.error "Expected files:"
        log.error "  - ${test_r1}"
        log.error "  - ${test_r2}"
        log.error ""
        log.error "Please add test data to tests/data/"
        exit 1
    }

    log.info "Test data found:"
    log.info "  - R1: ${test_r1.name} (${test_r1.size()} bytes)"
    log.info "  - R2: ${test_r2.name} (${test_r2.size()} bytes)"
    log.info ""

    // Create input channel
    ch_input = Channel.of([meta, [test_r1, test_r2]])

    // Run FASTP
    FASTP(ch_input)

    // Verify outputs
    FASTP.out.reads
        .view { m, reads ->
            log.info "✓ Trimmed reads produced:"
            reads.each { r -> log.info "    - ${r.name} (${r.size()} bytes)" }
        }

    FASTP.out.json
        .view { m, json ->
            log.info "✓ JSON report: ${json.name} (${json.size()} bytes)"
        }

    FASTP.out.html
        .view { m, html ->
            log.info "✓ HTML report: ${html.name} (${html.size()} bytes)"
        }

    FASTP.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    log.info ""
    log.info "═══════════════════════════════════════════════════════════════"
    if (workflow.success) {
        log.info "FASTP module test completed successfully!"
    } else {
        log.info "FASTP module test failed!"
    }
    log.info "═══════════════════════════════════════════════════════════════"
    log.info ""
}
