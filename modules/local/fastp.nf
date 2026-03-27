/*
========================================================================================
    FASTP - Illumina Read QC and Trimming
========================================================================================
    fastp performs quality control and trimming of Illumina paired-end reads

    Container: oras://ghcr.io/talasjudit/bsup-2555/fastp:1.0.1-1
    Documentation: https://github.com/OpenGene/fastp
========================================================================================
*/

process FASTP {
    tag "$meta.id"

    publishDir "${params.outdir}/qc/fastp", mode: 'copy', pattern: "*.{json,html}"

    container "${params.singularity_cachedir}/fastp-1.0.1.sif"

    input:
    tuple val(meta), path(reads)  // reads = [R1.fastq.gz, R2.fastq.gz]

    output:
    tuple val(meta), path('*_trimmed.fastq.gz'), emit: reads
    tuple val(meta), path('*.json')             , emit: json
    tuple val(meta), path('*.html')             , emit: html
    path 'versions.yml'                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    fastp \\
        --in1 ${reads[0]} \\
        --in2 ${reads[1]} \\
        --out1 ${prefix}_R1_trimmed.fastq.gz \\
        --out2 ${prefix}_R2_trimmed.fastq.gz \\
        --json ${prefix}.json \\
        --html ${prefix}.html \\
        --detect_adapter_for_pe \\
        --correction \\
        --qualified_quality_phred 20 \\
        --length_required 50 \\
        --thread ${task.cpus} \\
        ${args}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed 's/fastp //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_R1_trimmed.fastq.gz
    touch ${prefix}_R2_trimmed.fastq.gz
    touch ${prefix}.json
    touch ${prefix}.html
    touch versions.yml
    """
}
