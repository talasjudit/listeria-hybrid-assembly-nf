/*
========================================================================================
    POLYPOLISH - Illumina-Based Polishing of Long-Read Assemblies
========================================================================================
    Polypolish polishes a draft assembly (e.g. from Flye) using paired-end Illumina
    reads. BWA-MEM aligns each read end independently to the draft, and Polypolish
    corrects errors using per-base alignment pile-ups.

    Receives pre-aligned SAM files from BWA_MEM (which runs bwa index + bwa mem -a
    on the draft assembly independently for R1 and R2). This module performs:
      1. polypolish filter  : remove suspicious read pairs from the alignments
      2. polypolish polish  : correct errors using per-base alignment pile-ups

    BWA is run in a separate process (BWA_MEM) because the Polypolish container
    does not include BWA.

    Container: polypolish_0.6.1.sif
    Documentation: https://github.com/rrwick/Polypolish
========================================================================================
*/

process POLYPOLISH {
    tag "$meta.id"

    container "${params.singularity_cachedir}/polypolish_0.6.1.sif"

    publishDir "${params.outdir}/assembly/${params.assembly_mode}/polypolish", mode: 'copy', pattern: "*.log"

    input:
    tuple val(meta), path(draft_assembly), path(alignments_1), path(alignments_2)
    // draft_assembly : FASTA from Flye
    // alignments_1   : SAM from bwa mem -a (R1, all alignments)
    // alignments_2   : SAM from bwa mem -a (R2, all alignments)

    output:
    tuple val(meta), path("*_polypolish.fasta"), emit: assembly
    tuple val(meta), path("*_polypolish.log")  , emit: process_log
    path 'versions.yml'                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    polypolish filter \\
        --in1 ${alignments_1} --in2 ${alignments_2} \\
        --out1 filtered_1.sam --out2 filtered_2.sam
    polypolish polish ${args} ${draft_assembly} filtered_1.sam filtered_2.sam \\
        > ${prefix}_polypolish.fasta 2> ${prefix}_polypolish.log
    rm filtered_1.sam filtered_2.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        polypolish: \$(polypolish --version 2>&1 | sed 's/Polypolish //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_polypolish.fasta
    touch ${prefix}_polypolish.log
    touch versions.yml
    """
}
