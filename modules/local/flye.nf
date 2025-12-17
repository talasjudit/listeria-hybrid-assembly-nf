/*
========================================================================================
    FLYE - Long-Read De Novo Assembly
========================================================================================
    Flye is a de novo assembler for single-molecule sequencing reads (Nanopore/PacBio)

    Container: oras://ghcr.io/talasjudit/bsup-2555/flye:2.9.6-1
    Documentation: https://github.com/fenderglass/Flye

========================================================================================
*/

process FLYE {
    tag "$meta.id"

    container "${params.singularity_cachedir}/flye-2.9.6.sif"
    
    publishDir "${params.outdir}/assembly/flye", mode: 'copy'

    input:
    tuple val(meta), path(reads)  // reads = nanopore_filtlong.fastq.gz

    output:
    tuple val(meta), path("*_flye.fasta")     , emit: assembly
    tuple val(meta), path("*_flye_info.txt")  , emit: info
    tuple val(meta), path("*_flye.log")       , emit: process_log
    path 'versions.yml'                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def genome_size_arg = params.genome_size ? "--genome-size ${params.genome_size}" : ""

    """
    flye \\
        --nano-hq ${reads} \\
        --out-dir out_dir \\
        --threads ${task.cpus} \\
        ${genome_size_arg} \\
        ${args}

    # Rename and move outputs to standardize naming
    mv out_dir/assembly.fasta ${prefix}_flye.fasta
    mv out_dir/assembly_info.txt ${prefix}_flye_info.txt
    mv out_dir/flye.log ${prefix}_flye.log
    
    # Capture version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$(flye --version 2>&1 | sed 's/Flye //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_flye
    touch ${prefix}_flye.fasta
    touch ${prefix}_flye/assembly_info.txt
    touch ${prefix}_flye.log
    touch versions.yml
    """
}
