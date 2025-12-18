#!/usr/bin/env nextflow

/*
========================================================================================
    UNICYCLER Module Unit Test
========================================================================================
    Tests the UNICYCLER module in two modes:
    1. Standard Hybrid (Short + Long reads)
    2. Existing Assembly Mode (Short + Long + Flye Assembly)

    Usage:
      nextflow run tests/modules/unicycler/test_unicycler.nf -c nextflow.config -profile singularity,slurm
========================================================================================
*/

nextflow.enable.dsl=2

include { UNICYCLER } from '../../../modules/local/unicycler'

workflow {
    log.info "Testing UNICYCLER module..."

    // Define Inputs
    def r1 = file("${launchDir}/tests/data/test_R1.fastq.gz")
    def r2 = file("${launchDir}/tests/data/test_R2.fastq.gz")
    def nano = file("${launchDir}/tests/data/test_nanopore.fastq.gz")
    
    // --- TEST CASE 1: Standard Hybrid (No Assembly) ---
    // Input: [meta, [r1,r2], nano, []]  <-- Empty list for assembly
    def input_standard = [ [id:'test_unicycler_standard'], [r1, r2], nano, [] ]
    
    UNICYCLER( Channel.value(input_standard) )

    UNICYCLER.out.assembly.view { meta, fasta ->
        log.info "✓ [Standard] Assembly created: ${fasta.name}"
    }

    // --- TEST CASE 2: With Flye Assembly ---
    // Using the real Flye assembly output
    def flye_assembly = file("${launchDir}/tests/data/test_flye_assembly.fasta")
    def input_flye = [ [id:'test_unicycler_flye'], [r1, r2], nano, flye_assembly ]

    UNICYCLER_FLYE( Channel.value(input_flye) )

    UNICYCLER_FLYE.out.assembly.view { meta, fasta ->
        log.info "✓ [With-Flye] Assembly created: ${fasta.name}"
    }
}

// We need to alias the process to run it twice in the same script
include { UNICYCLER as UNICYCLER_FLYE } from '../../../modules/local/unicycler'
