#!/usr/bin/env nextflow
/*
========================================================================================
    Hybrid Bacterial Genome Assembly Pipeline - Entry Point
========================================================================================
    Github: https://github.com/talasjudit/hylisteria-nf

    This is the main entry point for the pipeline. It handles:
    - Help and version display
    - Parameter validation
    - Entry point routing (INSTALL vs main pipeline)

    The actual pipeline logic is in workflows/main.nf
========================================================================================
*/

nextflow.enable.dsl=2

/*
========================================================================================
    IMPORT WORKFLOWS
========================================================================================
*/

include { INSTALL as INSTALL_CONTAINERS } from "./workflows/install"
include { HYBRID_ASSEMBLY } from "./workflows/main"

/*
========================================================================================
    HELP MESSAGE
========================================================================================
    Strict DSL2 syntax (opt-in since 24.10, default in 26.04) disallows top-level
    statements, so the help text lives in a function and the --help / --version
    guards run inside the entry workflow below.
*/

def helpMessage() {
    return """
    ╔═══════════════════════════════════════════════════════════════╗
    ║         Hybrid Bacterial Genome Assembly Pipeline             ║
    ╚═══════════════════════════════════════════════════════════════╝

    Usage:
      # Install containers (run on login node with internet)
      nextflow run main.nf --install -profile singularity -resume

      # Run pipeline (can run on compute nodes)
      nextflow run main.nf --input samplesheet.csv --outdir results -profile singularity,slurm

    Required Arguments:
      --input                Path to samplesheet CSV file
      --outdir               Output directory for results

    Assembly Mode:
      --assembly_mode        Assembly strategy to use [default: unicycler]
                               unicycler      : Unicycler hybrid (Illumina + Nanopore) [default]
                               flye_unicycler : Flye → Unicycler (--existing_long_read_assembly)
                               flye_polypolish: Flye → Polypolish (Illumina polishing)
      --genome_size          Expected genome size for Flye-based modes [default: 3m]
      --reference            Reference FASTA for dnadiff QC (flye_polypolish only) [optional]

    QC Arguments:
      --min_read_length      Minimum Nanopore read length [default: 6000]
      --filtlong_keep_percent Keep top N% of Nanopore reads [default: 95]

    Resource Limits:
      --max_cpus             Maximum CPUs per process [default: 12]
      --max_memory           Maximum memory per process [default: 128.GB]
      --max_time             Maximum time per process [default: 24.h]

    Profiles:
      -profile singularity   Enable Singularity containers (required)
      -profile slurm         Use SLURM executor for HPC
      -profile local         Use local executor
      -profile test          Run with minimal test resources

    Modes:
      (default)              Run the assembly pipeline
      --install              Download and cache containers, then exit

    Examples:
      # 1. Install containers first (on login node)
      nextflow run main.nf --install -profile singularity -resume

      # 2. Basic pipeline run on SLURM
      nextflow run main.nf -profile singularity,slurm \\
        --input samplesheet.csv \\
        --outdir results

      # 3. Flye + Unicycler mode
      nextflow run main.nf -profile singularity,slurm \\
        --input samplesheet.csv \\
        --outdir results \\
        --assembly_mode flye_unicycler

      # 4. Flye + Polypolish mode with reference comparison
      nextflow run main.nf -profile singularity,slurm \\
        --input samplesheet.csv \\
        --outdir results \\
        --assembly_mode flye_polypolish \\
        --reference /path/to/reference.fasta

      # 5. Local execution with custom resources
      nextflow run main.nf -profile singularity,local \\
        --input samplesheet.csv \\
        --outdir results \\
        --max_cpus 8 \\
        --max_memory 32.GB

    For more details, see: https://github.com/talasjudit/hylisteria-nf
    """.stripIndent()
}

/*
========================================================================================
    RUN MAIN WORKFLOW (SINGLE ENTRY POINT)
========================================================================================
    Everything is routed from this one entry workflow. The `-entry` option is NOT
    supported by the strict syntax parser (default in Nextflow 26.04), so container
    installation is selected with `--install` rather than `-entry INSTALL`.
*/

workflow {
    // Help / version short-circuit (replaces the old top-level `exit 0` guards)
    if (params.help) {
        log.info helpMessage()
        return
    }

    if (params.version) {
        log.info """
        Pipeline: ${workflow.manifest.name}
        Version:  ${workflow.manifest.version}
        """.stripIndent()
        return
    }

    // Container installation mode: download + cache all SIFs, then stop.
    if (params.install) {
        INSTALL_CONTAINERS()
        return
    }

    HYBRID_ASSEMBLY()
}
