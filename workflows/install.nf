#!/usr/bin/env nextflow

/*
========================================================================================
    Container Installation Workflow
========================================================================================
    Downloads and verifies all Singularity containers for the hybrid assembly pipeline.
    Uses storeDir for automatic caching - already-downloaded containers are skipped.

    Usage: nextflow run main.nf -entry INSTALL -profile singularity -resume
========================================================================================
*/

nextflow.enable.dsl=2

// Container definitions: [filename, url, version_command]

def containers = [
    // Illumina QC
    ['fastp-1.0.1.sif', 'oras://ghcr.io/talasjudit/bsup-2555/fastp:1.0.1-1', 'fastp --version'],

    // MultiQC reporting
    ['multiqc-1.31.sif', 'oras://ghcr.io/talasjudit/bsup-2555/multiqc:1.31-1', 'multiqc --version'],

    // Nanopore QC
    ['porechop_abi-0.5.0.sif', 'oras://ghcr.io/talasjudit/bsup-2555/porechop_abi:0.5.0-1', 'porechop_abi --version'],
    ['filtlong-0.3.0.sif', 'oras://ghcr.io/talasjudit/bsup-2555/filtlong:0.3.0-1', 'filtlong --version'],

    // Coverage check
    ['seqkit-2.12.0.sif', 'oras://ghcr.io/talasjudit/bsup-2555/seqkit:2.12.0-1', 'seqkit version'],

    // Assembly
    ['flye-2.9.6.sif', 'oras://ghcr.io/talasjudit/bsup-2555/flye:2.9.6-1', 'flye --version'],
    ['unicycler-0.5.1.sif', 'docker://quay.io/biocontainers/unicycler:0.5.1--py39h746d604_5', 'unicycler --version'],

    // Assembly QC
    ['checkm2-1.1.0.sif', 'oras://ghcr.io/talasjudit/bsup-2555/checkm2:1.1.0-1', 'checkm2 --version'],
    ['quast-5.3.0.sif', 'oras://ghcr.io/talasjudit/bsup-2555/quast:5.3.0-1', 'quast.py --version']
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
    tuple val(filename), val(url), val(version_cmd)
    
    output:
    path filename
    
    script:
    """
    # Download the container
    singularity pull ${filename} ${url}
    
    # Verify container works by running version command
    echo "Verifying ${filename}..."
    singularity exec ${filename} ${version_cmd}
    echo "✓ ${filename} verified successfully"
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
     * Convert container list to channel
     * Each element is a tuple: [filename, url, version_cmd]
     */
    ch_containers = Channel.fromList(
        containers.collect { item ->
            tuple(item[0], item[1], item[2])
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

// Note: Completion handler moved to workflows/main.nf
// This file only defines the INSTALL workflow

// Note: Error handler moved to workflows/main.nf
