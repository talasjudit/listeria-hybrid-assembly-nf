#!/usr/bin/env nextflow
/*
========================================================================================
    QC_ASSEMBLY Subworkflow Test
========================================================================================
    Tests the QC_ASSEMBLY subworkflow: CheckM2 + QUAST in parallel
    
    Usage:
    nextflow run tests/subworkflows/qc_assembly/test_qc_assembly.nf \
        -c nextflow.config -profile singularity,slurm
========================================================================================
*/

nextflow.enable.dsl = 2

// Import the subworkflow
include { QC_ASSEMBLY } from '../../../subworkflows/local/qc_assembly'

println "Testing QC_ASSEMBLY subworkflow..."

workflow {
    // Create test input channel with assembly
    ch_assembly = Channel.of(
        [
            [id: 'test_sample', single_end: false],
            file("${launchDir}/tests/data/test_flye_assembly.fasta", checkIfExists: true)
        ]
    )

    // Run the subworkflow
    QC_ASSEMBLY(ch_assembly)

    // Verify outputs - use toList() to collect then subscribe to print
    QC_ASSEMBLY.out.checkm2_reports.toList().subscribe { items -> 
        items.each { meta, report -> println "✓ CheckM2 report: ${report.name}" }
    }

    QC_ASSEMBLY.out.quast_reports.toList().subscribe { items ->
        items.each { meta, report -> println "✓ QUAST report: ${report.name}" }
    }

    QC_ASSEMBLY.out.quast_html.toList().subscribe { items ->
        items.each { meta, html -> println "✓ QUAST HTML: ${html.name}" }
    }

    QC_ASSEMBLY.out.quast_icarus.toList().subscribe { items ->
        items.each { meta, icarus -> println "✓ QUAST Icarus: ${icarus.name}" }
    }

    QC_ASSEMBLY.out.versions.toList().subscribe { items ->
        items.each { version -> println "✓ Versions file: ${version.name}" }
    }
}

workflow.onComplete {
    println ""
    println "Pipeline completed!"
    println "Results in: ${params.outdir}"
}
