#!/usr/bin/env nextflow
/*
========================================================================================
    BWA_MEM Module Unit Test
========================================================================================
    Tests the BWA_MEM module: BWA index + paired-end alignment (-a flag) for
    Polypolish pre-processing. R1 and R2 are aligned independently to produce
    two SAM files.

    Requires (all committed):
      tests/data/test_flye_assembly.fasta
      tests/data/test_R1_small.fastq.gz
      tests/data/test_R2_small.fastq.gz

    Usage:
      nextflow run tests/modules/bwa_mem/test_bwa_mem.nf \
          -c nextflow.config -profile singularity,qib
========================================================================================
*/

nextflow.enable.dsl=2

include { BWA_MEM } from '../../../modules/local/bwa_mem'

// Verify required test data is present
def missing = ['test_flye_assembly.fasta', 'test_R1_small.fastq.gz', 'test_R2_small.fastq.gz'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nThese files should be committed to the repo — check tests/data/."
}

workflow {
    log.info "Testing BWA_MEM module..."

    def assembly = file("${launchDir}/tests/data/test_flye_assembly.fasta", checkIfExists: true)
    def r1       = file("${launchDir}/tests/data/test_R1_small.fastq.gz",   checkIfExists: true)
    def r2       = file("${launchDir}/tests/data/test_R2_small.fastq.gz",   checkIfExists: true)

    BWA_MEM(
        Channel.value([ [id: 'test_bwa_mem'], assembly, [r1, r2] ])
    )

    BWA_MEM.out.alignments
        .view { meta, asm, sam1, sam2 ->
            log.info "✓ Assembly passed through: ${asm.name}"
            log.info "✓ alignments_1.sam: ${sam1.name} (${sam1.size()} bytes)"
            log.info "✓ alignments_2.sam: ${sam2.name} (${sam2.size()} bytes)"
        }

    BWA_MEM.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "BWA_MEM test complete. Results in: ${params.outdir}"
}
