#!/usr/bin/env nextflow
/*
========================================================================================
    ASSEMBLY_UNICYCLER Subworkflow Test
========================================================================================
    Tests the ASSEMBLY_UNICYCLER subworkflow: standard Unicycler hybrid assembly
    (Illumina + Nanopore reads, no existing long-read assembly).

    Requires real FASTQ input files (not committed to the repo):
      tests/data/test_R1.fastq.gz
      tests/data/test_R2.fastq.gz
      tests/data/test_nanopore.fastq.gz

    Stage these files before running:
      sbatch tests/data/generate_test_assemblies.slurm

    Usage:
      nextflow run tests/subworkflows/assembly_unicycler/test_assembly_unicycler.nf \
          -c nextflow.config -profile singularity,qib

    Usage (stub run — no data or containers needed):
      nextflow run tests/subworkflows/assembly_unicycler/test_assembly_unicycler.nf \
          -c nextflow.config -profile singularity,qib -stub
========================================================================================
*/

nextflow.enable.dsl=2

include { ASSEMBLY_UNICYCLER } from '../../../subworkflows/local/assembly_unicycler'

// Verify required test data is present
def missing = ['test_R1.fastq.gz', 'test_R2.fastq.gz', 'test_nanopore.fastq.gz'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nStage reads first: sbatch tests/data/generate_test_assemblies.slurm"
}

workflow {
    log.info "Testing ASSEMBLY_UNICYCLER subworkflow..."

    ch_illumina = Channel.of([
        [id: 'test_sample', single_end: false],
        [
            file("${launchDir}/tests/data/test_R1.fastq.gz",       checkIfExists: true),
            file("${launchDir}/tests/data/test_R2.fastq.gz",       checkIfExists: true)
        ]
    ])

    ch_nanopore = Channel.of([
        [id: 'test_sample', single_end: true],
        file("${launchDir}/tests/data/test_nanopore.fastq.gz", checkIfExists: true)
    ])

    ASSEMBLY_UNICYCLER(ch_illumina, ch_nanopore)

    ASSEMBLY_UNICYCLER.out.assembly
        .view { meta, fasta ->
            log.info "✓ Assembly created: ${fasta.name} (${fasta.size()} bytes)"
        }

    ASSEMBLY_UNICYCLER.out.gfa
        .view { meta, gfa ->
            log.info "✓ Assembly graph: ${gfa.name}"
        }

    ASSEMBLY_UNICYCLER.out.logs
        .view { meta, log_file ->
            log.info "✓ Log: ${log_file.name}"
        }

    ASSEMBLY_UNICYCLER.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "ASSEMBLY_UNICYCLER test complete. Results in: ${params.outdir}"
}
