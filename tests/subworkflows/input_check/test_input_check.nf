#!/usr/bin/env nextflow
/*
========================================================================================
    INPUT_CHECK Subworkflow Test
========================================================================================
    Tests the INPUT_CHECK subworkflow: samplesheet parsing with nf-schema
    
    Usage:
    nextflow run tests/subworkflows/input_check/test_input_check.nf \
        -c nextflow.config -profile singularity,slurm \
        --input tests/data/samplesheet_test_abs.csv
========================================================================================
*/

nextflow.enable.dsl = 2

// Import the subworkflow
include { INPUT_CHECK } from '../../../subworkflows/local/input_check'

println "Testing INPUT_CHECK subworkflow..."

workflow {
    // The samplesheet path comes from params.input
    INPUT_CHECK(params.input)

    // Verify outputs
    INPUT_CHECK.out.illumina
        .view { meta, reads -> 
            "✓ Illumina reads: ${meta.id} -> ${reads.collect { it.name }}"
        }

    INPUT_CHECK.out.nanopore
        .view { meta, reads ->
            "✓ Nanopore reads: ${meta.id} -> ${reads.name}"
        }
}

workflow.onComplete {
    println ""
    println "Pipeline completed!"
    println "Samples parsed successfully."
}
