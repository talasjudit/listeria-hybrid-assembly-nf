#!/usr/bin/env nextflow
/*
========================================================================================
    POLYPOLISH Module Unit Test
========================================================================================
    Tests the POLYPOLISH module: Illumina-based polishing of a Flye draft assembly.

    BWA_MEM is imported and run first to generate the paired SAM files that
    POLYPOLISH requires. This mirrors the real pipeline where BWA_MEM feeds
    directly into POLYPOLISH.

    Requires (all committed):
      tests/data/test_flye_assembly.fasta
      tests/data/test_R1_small.fastq.gz
      tests/data/test_R2_small.fastq.gz

    Usage:
      nextflow run tests/modules/polypolish/test_polypolish.nf \
          -c nextflow.config -profile singularity,qib
========================================================================================
*/

nextflow.enable.dsl=2

include { BWA_MEM    } from '../../../modules/local/bwa_mem'
include { POLYPOLISH } from '../../../modules/local/polypolish'

// Verify required test data is present
def missing = ['test_flye_assembly.fasta', 'test_R1_small.fastq.gz', 'test_R2_small.fastq.gz'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nThese files should be committed to the repo — check tests/data/."
}

workflow {
    log.info "Testing POLYPOLISH module (via BWA_MEM → POLYPOLISH chain)..."

    def assembly = file("${launchDir}/tests/data/test_flye_assembly.fasta", checkIfExists: true)
    def r1       = file("${launchDir}/tests/data/test_R1_small.fastq.gz",   checkIfExists: true)
    def r2       = file("${launchDir}/tests/data/test_R2_small.fastq.gz",   checkIfExists: true)

    // Step 1: align R1 and R2 independently with BWA MEM -a
    BWA_MEM(
        Channel.value([ [id: 'test_polypolish'], assembly, [r1, r2] ])
    )

    // Step 2: pass BWA_MEM alignments directly to POLYPOLISH
    POLYPOLISH(BWA_MEM.out.alignments)

    POLYPOLISH.out.assembly
        .view { meta, fasta ->
            log.info "✓ Polished assembly: ${fasta.name} (${fasta.size()} bytes)"
        }

    POLYPOLISH.out.process_log
        .view { meta, log_file ->
            log.info "✓ Log: ${log_file.name}"
        }

    POLYPOLISH.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "POLYPOLISH test complete. Results in: ${params.outdir}"
}
