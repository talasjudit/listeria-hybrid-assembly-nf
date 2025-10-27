#!/usr/bin/env nextflow

/*
========================================================================================
    Container Installation Workflow
========================================================================================
    Downloads all Singularity containers needed for the hybrid assembly pipeline

    This workflow:
    - Downloads containers from GHCR and Quay.io
    - Caches nf-schema plugin for offline use
    - Checks if containers already exist (resumable)
    - Verifies successful downloads
    - Provides progress updates

    Usage:
      nextflow run workflows/install.nf

      # With custom cache directory
      nextflow run workflows/install.nf --singularity_cachedir /path/to/cache

    Requirements:
      - Singularity/Apptainer must be installed and in PATH
      - Internet connection for downloading containers and plugin
      - Sufficient disk space (~5-10 GB for all containers)

    Notes:
      - This workflow should be run on a node with internet access
      - On HPC systems without internet on compute nodes, run this on a login node
      - Downloads can be resumed if interrupted
      - Containers are shared across all pipeline runs using the same cache directory
      - Running this workflow also caches the nf-schema plugin to ~/.nextflow/plugins/
========================================================================================
*/

nextflow.enable.dsl=2

/*
========================================================================================
    PLUGINS
========================================================================================
    Include nf-schema plugin here so it gets cached during installation
    This allows the main pipeline to run offline on compute nodes
*/

plugins {
    id 'nf-schema@2.0.0'
}

/*
========================================================================================
    PARAMETERS
========================================================================================
*/

// Default cache directory for Singularity containers
params.singularity_cachedir = './singularity_cache'

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

    // Publish directly to cache directory
    publishDir params.singularity_cachedir, mode: 'copy', overwrite: false

    input:
    tuple val(filename), val(url)

    output:
    path filename

    script:
    """
    # Check if container already exists in cache directory
    if [ -f "${params.singularity_cachedir}/${filename}" ]; then
        echo "✓ Container ${filename} already exists in cache, skipping download"

        # Create symlink to existing file to satisfy Nextflow output requirement
        ln -s ${params.singularity_cachedir}/${filename} ${filename}

    else
        echo "════════════════════════════════════════════════════════════"
        echo "Downloading: ${filename}"
        echo "Source: ${url}"
        echo "════════════════════════════════════════════════════════════"

        # Download container using singularity pull
        singularity pull ${filename} ${url}

        # Verify download succeeded and file is not empty
        if [ ! -s ${filename} ]; then
            echo "ERROR: Download failed or file is empty: ${filename}"
            echo "Please check:"
            echo "  - Internet connection"
            echo "  - Singularity/Apptainer is properly installed"
            echo "  - Container URL is correct: ${url}"
            exit 1
        fi

        # Check file size is reasonable (at least 1MB)
        file_size=\$(stat -f%z "${filename}" 2>/dev/null || stat -c%s "${filename}" 2>/dev/null)
        if [ "\$file_size" -lt 1048576 ]; then
            echo "WARNING: Downloaded file is very small (\${file_size} bytes)"
            echo "This might indicate a failed download"
        fi

        echo "✓ Successfully downloaded ${filename}"
        echo ""
    fi
    """

    stub:
    """
    echo "STUB: Would download ${filename} from ${url}"
    touch ${filename}
    """
}

/*
========================================================================================
    WORKFLOW
========================================================================================
*/

workflow {

    /*
     * Print header with information
     */
    println """

    ╔═══════════════════════════════════════════════════════════════╗
    ║           Container Installation Workflow                     ║
    ║               Hybrid Assembly Pipeline                        ║
    ╚═══════════════════════════════════════════════════════════════╝

    Cache directory: ${params.singularity_cachedir}
    Containers to download: ${containers.size()}

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
        .view { files ->
            def summary = """

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
                summary += "  ✓ ${file.name.padRight(30)} (${sizeStr})\n"
            }

            summary += """

            Cache directory: ${params.singularity_cachedir}

            Next steps:
            1. Verify containers with: ls -lh ${params.singularity_cachedir}
            2. Run the pipeline with: nextflow run main.nf -profile singularity,slurm --input samplesheet.csv

            """.stripIndent()

            println summary
        }
}

/*
========================================================================================
    COMPLETION HANDLERS
========================================================================================
*/

workflow.onComplete {
    println ""
    println "═══════════════════════════════════════════════════════════════"

    if (workflow.success) {
        println "Installation workflow completed successfully!"
        println "═══════════════════════════════════════════════════════════════"
        println ""
        println "All containers are now available in: ${params.singularity_cachedir}"
        println ""
        println "You can now run the pipeline:"
        println "  nextflow run main.nf -profile singularity,slurm --input samplesheet.csv"
        println ""
    } else {
        println "Installation workflow failed!"
        println "═══════════════════════════════════════════════════════════════"
        println ""
        println "Please check the error messages above."
        println ""
        println "Common issues:"
        println "  - No internet connection"
        println "  - Singularity/Apptainer not installed or not in PATH"
        println "  - Insufficient disk space"
        println "  - Container URL changed or is unavailable"
        println ""
        println "For help, see: https://github.com/yourusername/listeria-hybrid-nf/issues"
        println ""
    }
}

workflow.onError {
    println ""
    println "═══════════════════════════════════════════════════════════════"
    println "Installation stopped with error:"
    println workflow.errorMessage
    println "═══════════════════════════════════════════════════════════════"
    println ""
}
