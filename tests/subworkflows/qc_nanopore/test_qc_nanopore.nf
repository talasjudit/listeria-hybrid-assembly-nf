#!/usr/bin/env nextflow
/*
========================================================================================
    QC_NANOPORE Subworkflow Test
========================================================================================
    Tests the QC_NANOPORE subworkflow: PORECHOP_ABI → FILTLONG chain
    
    Usage:
    nextflow run tests/subworkflows/qc_nanopore/test_qc_nanopore.nf \
        -c nextflow.config -profile singularity,slurm
========================================================================================
*/

nextflow.enable.dsl = 2

// Import the subworkflow
include { QC_NANOPORE } from '../../../subworkflows/local/qc_nanopore'

println "Testing QC_NANOPORE subworkflow..."

workflow {
    // Create test input channel with Nanopore reads
    ch_nanopore = Channel.of(
        [
            [id: 'test_sample', single_end: true],
            file("${launchDir}/tests/data/test_nanopore.fastq.gz", checkIfExists: true)
        ]
    )

    // Run the subworkflow
    QC_NANOPORE(ch_nanopore)

    // Verify outputs
    QC_NANOPORE.out.reads
        .view { meta, reads -> 
            "✓ QC'd reads: ${reads.name} (${reads.size()} bytes)"
        }

    QC_NANOPORE.out.logs
        .view { meta, log ->
            "✓ Log file: ${log.name}"
        }

    QC_NANOPORE.out.versions
        .view { versions ->
            "✓ Versions file: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "Pipeline completed!"
    println "Results in: ${params.outdir}"
}
