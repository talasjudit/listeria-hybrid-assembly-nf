#!/usr/bin/env nextflow
/*
========================================================================================
    ASSEMBLY_POLYPOLISH Subworkflow Test
========================================================================================
    Tests the ASSEMBLY_POLYPOLISH subworkflow: Flye assembly polished with Illumina
    reads via BWA MEM → Polypolish.

    Uses committed small test data (10k subsampled reads) — no HPC staging required.

    Requires (all committed):
      tests/data/test_flye_assembly.fasta
      tests/data/test_R1_small.fastq.gz
      tests/data/test_R2_small.fastq.gz

    Usage (stub run — POLYPOLISH script not yet implemented):
      nextflow run tests/subworkflows/assembly_polypolish/test_assembly_polypolish.nf \
          -c nextflow.config -profile singularity,qib -stub

    Usage (full run, after polypolish.nf script is implemented):
      nextflow run tests/subworkflows/assembly_polypolish/test_assembly_polypolish.nf \
          -c nextflow.config -profile singularity,qib
========================================================================================
*/

nextflow.enable.dsl=2

include { ASSEMBLY_POLYPOLISH } from '../../../subworkflows/local/assembly_polypolish'

// Verify required test data is present
def missing = ['test_flye_assembly.fasta', 'test_R1_small.fastq.gz', 'test_R2_small.fastq.gz'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nThese files should be committed to the repo — check tests/data/."
}

workflow {
    log.info "Testing ASSEMBLY_POLYPOLISH subworkflow..."

    ch_illumina = Channel.of([
        [id: 'test_sample', single_end: false],
        [
            file("${launchDir}/tests/data/test_R1_small.fastq.gz",     checkIfExists: true),
            file("${launchDir}/tests/data/test_R2_small.fastq.gz",     checkIfExists: true)
        ]
    ])

    ch_flye_assembly = Channel.of([
        [id: 'test_sample', single_end: false],
        file("${launchDir}/tests/data/test_flye_assembly.fasta",       checkIfExists: true)
    ])

    ASSEMBLY_POLYPOLISH(ch_illumina, ch_flye_assembly)

    ASSEMBLY_POLYPOLISH.out.assembly
        .view { meta, fasta ->
            log.info "✓ Polished assembly: ${fasta.name} (${fasta.size()} bytes)"
        }

    ASSEMBLY_POLYPOLISH.out.logs
        .view { meta, log_file ->
            log.info "✓ Log: ${log_file.name}"
        }

    ASSEMBLY_POLYPOLISH.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "ASSEMBLY_POLYPOLISH test complete. Results in: ${params.outdir}"
}
