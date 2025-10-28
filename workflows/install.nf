#!/usr/bin/env nextflow

/*
========================================================================================
    Container Installation Workflow
========================================================================================
    Downloads all Singularity containers needed for the hybrid assembly pipeline

    This workflow:
    - Downloads containers from GHCR and Quay.io
    - Caches nf-schema plugin for offline use (from nextflow.config)
    - Uses storeDir to skip already-downloaded containers (auto-resumable)
    - Verifies successful downloads
    - Provides progress updates

    Usage:
      nextflow run main.nf -entry INSTALL -profile singularity -resume

      # With custom cache directory
      nextflow run main.nf -entry INSTALL -profile singularity \\
        --singularity_cachedir /path/to/cache

    Requirements:
      - Singularity/Apptainer must be installed and in PATH
      - Internet connection for downloading containers and plugin
      - Sufficient disk space (~5-10 GB for all containers)

    Notes:
      - This workflow should be run on a node with internet access
      - On HPC systems without internet on compute nodes, run this on a login node
      - Downloads can be resumed if interrupted (-resume flag)
      - Containers are shared across all pipeline runs using the same cache directory
      - Running this workflow also caches the nf-schema plugin to ~/.nextflow/plugins/
========================================================================================
*/

nextflow.enable.dsl=2

/*
========================================================================================
    CONTAINER DEFINITIONS
========================================================================================
    Map of container filenames to their source URLs

    Note: Using consistent naming scheme: <tool>-<version>.sif
*/

def containers = [
    // Illumina QC
    'fastp-1.0.1.sif': 'oras://ghcr.io/talasjudit/bsup-2555/fastp:1.0.1-1',

    // MultiQC reporting
    'multiqc-1.31.sif': 'oras://ghcr.io/talasjudit/bsup-2555/multiqc:1.31-1',

    // Nanopore QC
    'porechop_abi-0.5.0.sif': 'oras://ghcr.io/talasjudit/bsup-2555/porechop_abi:0.5.0-1',
    'filtlong-0.3.0.sif': 'oras://ghcr.io/talasjudit/bsup-2555/filtlong:0.3.0-1',

    // Assembly
    'flye-2.9.6.sif': 'oras://ghcr.io/talasjudit/bsup-2555/flye:2.9.6-1',
    'unicycler-0.5.1.sif': 'docker://quay.io/biocontainers/unicycler:0.5.1--py39h746d604_5',

    // Assembly QC
    'checkm2-1.1.0.sif': 'oras://ghcr.io/talasjudit/bsup-2555/checkm2:1.1.0-1',
    'quast-5.3.0.sif': 'oras://ghcr.io/talasjudit/bsup-2555/quast:5.3.0-1'
]

/*
========================================================================================
    PROCESSES
========================================================================================
*/

process DOWNLOAD_CONTAINER {
    tag "$filename"
    storeDir params.singularity_cachedir
    
    input:
    tuple val(filename), val(url)
    
    output:
    path filename
    
    script:
    """
    singularity pull ${filename} ${url}
    """
}

/*
========================================================================================
    WORKFLOW
========================================================================================
*/

workflow INSTALL {

    /*
     * Print header with information
     */
    log.info """

    ╔═══════════════════════════════════════════════════════════════╗
    ║           Container Installation Workflow                     ║
    ║               Hybrid Assembly Pipeline                        ║
    ╚═══════════════════════════════════════════════════════════════╝

    Cache directory: ${params.singularity_cachedir}
    Containers to download: ${containers.size()}

    Note: This workflow uses storeDir, so already-downloaded containers
    will be automatically skipped. Use -resume to skip completed downloads
    if the workflow was interrupted.

    """.stripIndent()

    /*
     * Create cache directory if it doesn't exist
     */
    file(params.singularity_cachedir).mkdirs()

    /*
     * Convert container map to channel
     * Each element is a tuple: [filename, url]
     */
    ch_containers = Channel.fromList(
        containers.collect { filename, url ->
            tuple(filename, url)
        }
    )

    /*
     * Download all containers
     */
    DOWNLOAD_CONTAINER(ch_containers)

    /*
     * Collect all downloads and print summary
     */
    DOWNLOAD_CONTAINER.out
        .collect()
        .subscribe { files ->
            println """

            ╔═══════════════════════════════════════════════════════════════╗
            ║              Installation Complete!                           ║
            ╚═══════════════════════════════════════════════════════════════╝

            Successfully processed ${files.size()} containers:
            """.stripIndent()

            files.each { file ->
                // Get file size
                def size = file.size()
                def sizeStr = size > 1073741824 ? "${String.format('%.2f', size / 1073741824)} GB" :
                              size > 1048576 ? "${String.format('%.2f', size / 1048576)} MB" :
                              "${String.format('%.2f', size / 1024)} KB"
                println "  ✓ ${file.name.padRight(30)} (${sizeStr})"
            }

            println """

            Cache directory: ${params.singularity_cachedir}

            Next steps:
            1. Verify containers with: ls -lh ${params.singularity_cachedir}
            2. Run the pipeline with: nextflow run main.nf -profile singularity,slurm --input samplesheet.csv

            """.stripIndent()
        }
}

/*
========================================================================================
    COMPLETION HANDLERS
========================================================================================
*/

workflow.onComplete {
    log.info ""
    log.info "═══════════════════════════════════════════════════════════════"

    if (workflow.success) {
        log.info "Installation workflow completed successfully!"
        log.info "═══════════════════════════════════════════════════════════════"
        log.info ""
        log.info "All containers are now available in: ${params.singularity_cachedir}"
        log.info ""
        log.info "You can now run the pipeline:"
        log.info "  nextflow run main.nf -profile singularity,slurm --input samplesheet.csv"
        log.info ""
    } else {
        log.info "Installation workflow failed!"
        log.info "═══════════════════════════════════════════════════════════════"
        log.info ""
        log.info "Please check the error messages above."
        log.info ""
        log.info "Common issues:"
        log.info "  - No internet connection"
        log.info "  - Singularity/Apptainer not installed or not in PATH"
        log.info "  - Insufficient disk space"
        log.info "  - Container URL changed or is unavailable"
        log.info ""
        log.info "For help, see: https://github.com/yourusername/listeria-hybrid-nf/issues"
        log.info ""
    }
}

workflow.onError {
    log.error ""
    log.error "═══════════════════════════════════════════════════════════════"
    log.error "Installation stopped with error:"
    log.error workflow.errorMessage
    log.error "═══════════════════════════════════════════════════════════════"
    log.error ""
}
