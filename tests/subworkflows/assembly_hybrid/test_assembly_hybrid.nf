#!/usr/bin/env nextflow
/*
========================================================================================
    ASSEMBLY_HYBRID Subworkflow Test
========================================================================================
    Tests the ASSEMBLY_HYBRID subworkflow: Unicycler with optional Flye assembly
    (Updated module outputs to process_log)
    
    Usage (without Flye):
    nextflow run tests/subworkflows/assembly_hybrid/test_assembly_hybrid.nf \
        -c nextflow.config -profile singularity,slurm
    
    Usage (with Flye assembly):
    nextflow run tests/subworkflows/assembly_hybrid/test_assembly_hybrid.nf \
        -c nextflow.config -profile singularity,slurm --use_flye true
========================================================================================
*/

nextflow.enable.dsl = 2

// Import the subworkflow
include { ASSEMBLY_HYBRID } from '../../../subworkflows/local/assembly_hybrid'

println "Testing ASSEMBLY_HYBRID subworkflow..."
println "Mode: ${params.use_flye ? 'With Flye assembly' : 'Standard hybrid'}"

workflow {
    // Create test input channels
    ch_illumina = Channel.of(
        [
            [id: 'test_sample', single_end: false],
            [
                file("${launchDir}/tests/data/test_R1.fastq.gz", checkIfExists: true),
                file("${launchDir}/tests/data/test_R2.fastq.gz", checkIfExists: true)
            ]
        ]
    )

    ch_nanopore = Channel.of(
        [
            [id: 'test_sample', single_end: false],
            file("${launchDir}/tests/data/test_nanopore.fastq.gz", checkIfExists: true)
        ]
    )

    // Conditionally create Flye assembly channel
    if (params.use_flye) {
        ch_flye = Channel.of(
            [
                [id: 'test_sample', single_end: false],
                file("${launchDir}/tests/data/test_flye_assembly.fasta", checkIfExists: true)
            ]
        )
    } else {
        ch_flye = Channel.empty()
    }

    // Run the subworkflow
    ASSEMBLY_HYBRID(ch_illumina, ch_nanopore, ch_flye)

    // Verify outputs
    ASSEMBLY_HYBRID.out.assembly.view { "Starting verification..." }

    ASSEMBLY_HYBRID.out.assembly
        .view { meta, assembly -> 
            "✓ Assembly: ${assembly.name}"
        }

    ASSEMBLY_HYBRID.out.gfa
        .view { meta, gfa ->
            "✓ GFA graph: ${gfa.name}"
        }

    ASSEMBLY_HYBRID.out.logs
        .view { meta, log ->
            "✓ Log: ${log.name}"
        }
}

workflow.onComplete {
    println ""
    println "Pipeline completed!"
    println "Results in: ${params.outdir}"
}
