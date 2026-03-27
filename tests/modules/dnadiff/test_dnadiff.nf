#!/usr/bin/env nextflow
/*
========================================================================================
    DNADIFF Module Unit Test
========================================================================================
    Tests the DNADIFF module: assembly vs reference comparison using MUMmer dnadiff.

    Uses two distinct committed assemblies from the same sample:
      Assembly  : tests/data/test_unicycler_assembly.fasta
      Reference : tests/data/test_flye_assembly.fasta

    The reference is passed as a Channel.value (broadcast to all samples) to match
    how it is used in the main pipeline.

    Usage:
      nextflow run tests/modules/dnadiff/test_dnadiff.nf \
          -c nextflow.config -profile singularity,qib
========================================================================================
*/

nextflow.enable.dsl=2

include { DNADIFF } from '../../../modules/local/dnadiff'

// Verify required test data is present
def missing = ['test_flye_assembly.fasta', 'test_unicycler_assembly.fasta'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nThese files should be committed to the repo — check tests/data/."
}

workflow {
    log.info "Testing DNADIFF module..."

    def assembly  = file("${launchDir}/tests/data/test_unicycler_assembly.fasta", checkIfExists: true)
    def reference = file("${launchDir}/tests/data/test_flye_assembly.fasta",      checkIfExists: true)

    ch_assembly  = Channel.value([ [id: 'test_dnadiff'], assembly ])
    ch_reference = Channel.value(reference)

    DNADIFF(ch_assembly, ch_reference)

    DNADIFF.out.report
        .view { meta, report ->
            log.info "✓ Report: ${report.name}"
        }

    DNADIFF.out.delta
        .view { meta, delta ->
            log.info "✓ Delta: ${delta.name}"
        }

    DNADIFF.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "DNADIFF test complete. Results in: ${params.outdir}"
}
