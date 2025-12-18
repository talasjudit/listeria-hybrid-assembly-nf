#!/usr/bin/env nextflow

/*
========================================================================================
    CHECKM2 Module Unit Test
========================================================================================
    Tests the CHECKM2 module for assembly quality assessment.
========================================================================================
*/

nextflow.enable.dsl=2

include { CHECKM2 } from '../../../modules/local/checkm2'

workflow {
    log.info "Testing CHECKM2 module..."

    // Input: Flye assembly from previous test
    def assembly = file("${launchDir}/tests/data/test_flye_assembly.fasta")
    def input = [ [id:'test_checkm2'], assembly ]
    
    CHECKM2( Channel.value(input) )

    CHECKM2.out.report.view { meta, report ->
        log.info "✓ Quality Report created: ${report.name}"
    }
}
