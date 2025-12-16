#!/usr/bin/env nextflow

/*
========================================================================================
    QUAST Module Unit Test
========================================================================================
    Tests the QUAST module for assembly metrics.
========================================================================================
*/

nextflow.enable.dsl=2

include { QUAST } from '../../../modules/local/quast'

workflow {
    log.info "Testing QUAST module..."

    // Input: Flye assembly from previous test
    def assembly = file("${launchDir}/tests/data/test_flye_assembly.fasta")
    def input = [ [id:'test_quast'], assembly ]
    
    QUAST( Channel.value(input) )

    QUAST.out.report.view { meta, report ->
        log.info "✓ Summary Report created: ${report.name}"
    }
    
    QUAST.out.html.view { meta, html ->
        log.info "✓ HTML Report created: ${html.name}"
    }
}
