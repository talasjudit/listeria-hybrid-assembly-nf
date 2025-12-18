#!/usr/bin/env nextflow
/*
========================================================================================
    Hybrid Bacterial Genome Assembly Pipeline - Entry Point
========================================================================================
    Github: https://github.com/talasjudit/listeria-hybrid-nf
    
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
*/

if (params.help) {
    log.info """
    ╔═══════════════════════════════════════════════════════════════╗
    ║         Hybrid Bacterial Genome Assembly Pipeline             ║
    ╚═══════════════════════════════════════════════════════════════╝

    Usage:
      # Install containers (run on login node with internet)
      nextflow run main.nf -entry INSTALL -profile singularity -resume

      # Run pipeline (can run on compute nodes)
      nextflow run main.nf --input samplesheet.csv --outdir results -profile singularity,slurm

    Required Arguments:
      --input                Path to samplesheet CSV file
      --outdir               Output directory for results

    Optional Arguments:
      --use_flye             Run Flye assembly before Unicycler [default: false]
      --genome_size          Expected genome size for Flye [default: 3m]
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

    Entry Points:
      (default)              Run the assembly pipeline
      -entry INSTALL         Download and cache containers

    Examples:
      # 1. Install containers first (on login node)
      nextflow run main.nf -entry INSTALL -profile singularity -resume

      # 2. Basic pipeline run on SLURM
      nextflow run main.nf -profile singularity,slurm \\
        --input samplesheet.csv \\
        --outdir results

      # 3. With Flye pre-assembly
      nextflow run main.nf -profile singularity,slurm \\
        --input samplesheet.csv \\
        --outdir results \\
        --use_flye

      # 4. Local execution with custom resources
      nextflow run main.nf -profile singularity,local \\
        --input samplesheet.csv \\
        --outdir results \\
        --max_cpus 8 \\
        --max_memory 32.GB

    For more details, see: https://github.com/talasjudit/listeria-hybrid-nf
    """.stripIndent()
    exit 0
}

// Print version if requested
if (params.version) {
    log.info """
    Pipeline: ${workflow.manifest.name}
    Version:  ${workflow.manifest.version}
    """.stripIndent()
    exit 0
}

/*
========================================================================================
    NAMED WORKFLOWS
========================================================================================
*/

/*
 * WORKFLOW: INSTALL
 * Download and cache all Singularity containers
 */
workflow INSTALL {
    INSTALL_CONTAINERS()
}

/*
========================================================================================
    RUN MAIN WORKFLOW (DEFAULT ENTRY POINT)
========================================================================================
*/

workflow {
    HYBRID_ASSEMBLY()
}
