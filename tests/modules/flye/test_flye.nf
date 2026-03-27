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

include { FLYE } from '../../../modules/local/flye'

// Verify required test data is present
def missing = ['test_nanopore.fastq.gz'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nRun: bash tests/data/download_test_data.sh\nNote: requires internet access - on HPC, run from a login node first."
}

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
