/*
========================================================================================
    FILTLONG - Nanopore Read Quality Filtering
========================================================================================
    Filtlong filters long reads by quality.

    Container: oras://ghcr.io/talasjudit/bsup-2555/filtlong:0.3.0-1
    Documentation: https://github.com/rrwick/Filtlong

========================================================================================
*/

process FILTLONG {
    tag "$meta.id"

    container "${params.singularity_cachedir}/filtlong-0.3.0.sif"

    input:
    tuple val(meta), path(reads)  // reads = nanopore_porechop.fastq.gz

    output:
    tuple val(meta), path('*_filtlong.fastq.gz'), emit: reads
    tuple val(meta), path('*.log')               , emit: log
    path 'versions.yml'                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    filtlong \\
        --min_length ${params.min_read_length} \\
        --keep_percent ${params.filtlong_keep_percent} \\
        ${args} \\
        ${reads} \\
        2> ${prefix}_filtlong.log \\
        | gzip > ${prefix}_filtlong.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filtlong: \$(filtlong --version 2>&1 | sed 's/Filtlong v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_filtlong.fastq.gz
    touch ${prefix}_filtlong.log
    touch versions.yml
    """
}
