/*
========================================================================================
    PORECHOP_ABI - Nanopore Adapter Trimming
========================================================================================
    Porechop ABI finds and removes adapters from Oxford Nanopore reads
    
    Container: oras://ghcr.io/talasjudit/bsup-2555/porechop_abi:0.5.0-1
    Documentation: https://github.com/bonsai-team/Porechop_ABI
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

    """
    porechop_abi \\
        -i ${reads} \\
        -o ${prefix}_porechop.fastq.gz \\
        --threads ${task.cpus} \\
        --ab_initio \\
        --verbosity 2 \\
        ${args} \\
        > ${prefix}_porechop.log 2>&1
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        porechop_abi: \$(porechop_abi --version 2>&1 | head -1)
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
