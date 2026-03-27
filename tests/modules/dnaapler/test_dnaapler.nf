#!/usr/bin/env nextflow
/*
========================================================================================
    DNAAPLER Module Unit Test
========================================================================================
    Tests the DNAAPLER module: chromosome reorientation to dnaA using MMseqs2.

    Requires (committed):
      tests/data/test_flye_assembly.fasta

    Usage:
      nextflow run tests/modules/dnaapler/test_dnaapler.nf \
          -c nextflow.config -profile singularity,qib
========================================================================================
*/

nextflow.enable.dsl=2

include { DNAAPLER } from '../../../modules/local/dnaapler'

// Verify required test data is present
def missing = ['test_flye_assembly.fasta'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nThese files should be committed to the repo — check tests/data/."
}

workflow {
    log.info "Testing DNAAPLER module..."

    def assembly = file("${launchDir}/tests/data/test_flye_assembly.fasta", checkIfExists: true)

    DNAAPLER(
        Channel.value([ [id: 'test_dnaapler'], assembly ])
    )

    DNAAPLER.out.assembly
        .view { meta, fasta ->
            log.info "✓ Reoriented assembly: ${fasta.name} (${fasta.size()} bytes)"
        }

    DNAAPLER.out.process_log
        .view { meta, log_file ->
            log.info "✓ Log: ${log_file.name}"
        }

    DNAAPLER.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "DNAAPLER test complete. Results in: ${params.outdir}"
}
