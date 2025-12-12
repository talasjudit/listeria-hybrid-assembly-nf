#!/usr/bin/env nextflow

/*
========================================================================================
    COVERAGE_CHECK Module Unit Test
========================================================================================
    Unified test for COVERAGE_CHECK module.
    Adapts validation logic based on input parameters.

    1. Test PASS (Default):
       nextflow run tests/modules/coverage_check/test_coverage_check.nf -c nextflow.config -profile singularity,slurm

    2. Test FAIL (High Thresholds):
       nextflow run tests/modules/coverage_check/test_coverage_check.nf \
         -c nextflow.config \
         -c tests/modules/coverage_check/fail.config \
         -profile singularity,slurm
========================================================================================
*/

nextflow.enable.dsl=2

include { COVERAGE_CHECK } from '../../../modules/local/coverage_check'

workflow {
    log.info "Testing COVERAGE_CHECK..."
    log.info "Params: Min Illumina Cov = ${params.min_illumina_coverage}x"
    log.info "Params: Min Nanopore Cov = ${params.min_nanopore_coverage}x"

    // 1. Inputs
    def r1 = file("${launchDir}/tests/data/test_R1.fastq.gz")
    def r2 = file("${launchDir}/tests/data/test_R2.fastq.gz")
    def nano = file("${launchDir}/tests/data/test_nanopore.fastq.gz")
    
    // Note: R1/R2 grouped as list
    def input = [ [id:'test_sample'], [r1, r2], nano ]
    
    // 2. Run Module
    COVERAGE_CHECK( Channel.value(input) )

    // 3. Verify Output
    COVERAGE_CHECK.out.results
        .view { meta, illumina_files, nanopore_file, report_file ->
            def report_content = report_file.text
            def status_passed = report_content.contains("Status: PASSED")
            def status_failed = report_content.contains("Status: FAILED")
            
            log.info "------------------------------------------------"
            log.info "Sample: ${meta.id}"
            log.info "Report Status: " + (status_passed ? "PASSED" : "FAILED")

            // SMART VALIDATION LOGIC
            // If thresholds are set to the "Review/Fail" level (e.g. 10000), we EXPECT failure.
            if (params.min_illumina_coverage == 10000) {
                if (status_failed) {
                    log.info "✓ SUCCESS: Sample correctly FAILED QC (as expected due to high thresholds)."
                } else {
                    log.error "✘ ERROR: Sample SHOULD HAVE FAILED but PASSED!"
                }
            } 
            // Otherwise, we EXPECT pass (assuming test data is good)
            else {
                if (status_passed) {
                   log.info "✓ SUCCESS: Sample correctly PASSED QC."
                } else {
                   log.error "✘ ERROR: Sample SHOULD HAVE PASSED but FAILED!"
                   log.error "Report Content:\n${report_content}"
                }
            }
            log.info "------------------------------------------------"
        }
}
