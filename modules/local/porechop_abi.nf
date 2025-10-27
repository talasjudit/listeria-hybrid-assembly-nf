/*
========================================================================================
    PORECHOP_ABI - Nanopore Adapter Trimming
========================================================================================
    Porechop ABI finds and removes adapters from Oxford Nanopore reads

    Key features:
    - Detects adapters using ab initio method
    - Handles barcoded and non-barcoded data
    - Removes adapters from read ends and middle (chimeras)

    Container: oras://ghcr.io/talasjudit/bsup-2555/porechop_abi:0.5.0-1
    Documentation: https://github.com/bonsai-team/Porechop_ABI

    TODO: Implement porechop_abi command in Phase 2+
========================================================================================
*/

process PORECHOP_ABI {
    tag "$meta.id"

    container "${params.singularity_cachedir}/porechop_abi-0.5.0.sif"

    input:
    tuple val(meta), path(reads)  // reads = nanopore.fastq.gz

    output:
    tuple val(meta), path('*_porechop.fastq.gz'), emit: reads
    tuple val(meta), path('*.log')               , emit: log
    path 'versions.yml'                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO Phase 2: Implement porechop_abi command
    // Expected input:
    //   - reads = nanopore.fastq.gz (Nanopore long reads)
    //
    // Expected outputs:
    //   - ${prefix}_porechop.fastq.gz (adapter-trimmed Nanopore reads)
    //   - ${prefix}_porechop.log (log file with adapter detection info)
    //
    // Key parameters to include:
    //   --ab_initio : Use ab initio adapter detection (recommended)
    //   --threads ${task.cpus} : Use allocated CPUs
    //   --input ${reads} : Input Nanopore reads
    //   --output ${prefix}_porechop.fastq.gz : Output trimmed reads
    //   ${args} : Additional user-specified arguments
    //
    // Additional options to consider:
    //   --discard_middle : Remove reads with middle adapters (chimeras)
    //   --check_reads 10000 : Number of reads to check for adapters
    //
    // Log capture:
    //   Redirect stdout/stderr to ${prefix}_porechop.log for diagnostics

    """
    # TODO: Implement porechop_abi command here

    echo "TODO: Run porechop_abi on ${reads}"
    echo "TODO: Output adapter-trimmed reads to ${prefix}_porechop.fastq.gz"
    echo "TODO: Save log to ${prefix}_porechop.log"

    # Placeholder command - remove this in Phase 2
    touch ${prefix}_porechop.fastq.gz
    touch ${prefix}_porechop.log

    # Version capture - TODO: Update with actual porechop version command
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        porechop_abi: \$(porechop_abi --version 2>&1 | sed 's/porechop_abi //g' || echo "version_unavailable")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_porechop.fastq.gz
    touch ${prefix}_porechop.log
    touch versions.yml
    """
}
