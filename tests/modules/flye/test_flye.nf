#!/usr/bin/env nextflow

/*
========================================================================================
    FLYE Module Unit Test
========================================================================================
    Tests the FLYE module for long-read assembly.

    Usage:
      nextflow run tests/modules/flye/test_flye.nf -c nextflow.config -profile singularity,slurm
========================================================================================
*/

nextflow.enable.dsl=2

// Import module
include { FLYE } from '../../../modules/local/flye'

workflow {
    log.info "Testing FLYE module..."

    // 1. Inputs
    // We use the raw nanopore data as 'filtered reads' for this unit test
    def nano = file("${launchDir}/tests/data/test_nanopore.fastq.gz")
    
    // Create tuple matching process definition: tuple val(meta), path(reads)
    def input = [ [id:'test_flye'], nano ]
    
    // 2. Run Module
    // Use Channel.value to correctly pass the single tuple
    FLYE( Channel.value(input) )

    // 3. Verify Outputs
    FLYE.out.assembly.view { meta, fasta ->
        log.info "✓ Assembly created: ${fasta.name} (${fasta.size()} bytes)"
    }
    
    FLYE.out.info.view { meta, info ->
        log.info "✓ Info file created: ${info.name}"
    }

    FLYE.out.versions.view { versions ->
        log.info "✓ Version info captured"
    }
}
