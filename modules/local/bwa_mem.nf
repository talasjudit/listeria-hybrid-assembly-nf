/*
========================================================================================
    BWA_MEM - Short-Read Alignment for Polypolish Pre-processing
========================================================================================
    Aligns paired-end Illumina reads to a draft assembly using BWA MEM with the -a flag
    (retain all alignments, including secondary). This is required by Polypolish, which
    uses pile-up depth at every position to correct errors. Standard aligners report only
    the best alignment per read; -a ensures Polypolish has full coverage information.

    Both read ends are aligned independently (R1 and R2 in separate bwa mem calls) and
    output as separate SAM files. This is a Polypolish requirement.

    Container: bwa-0.7.19.sif
    Documentation: https://github.com/lh3/bwa
========================================================================================
*/

process BWA_MEM {
    tag "$meta.id"

    container "${params.singularity_cachedir}/bwa-0.7.19.sif"

    input:
    tuple val(meta), path(assembly), path(illumina_reads)
    // assembly       : draft FASTA (e.g. from Flye)
    // illumina_reads : [R1.fastq.gz, R2.fastq.gz]

    output:
    tuple val(meta), path(assembly), path("alignments_1.sam"), path("alignments_2.sam"), emit: alignments
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def r1 = illumina_reads[0]
    def r2 = illumina_reads[1]
    """
    cp ${assembly} assembly_local.fasta
    bwa index assembly_local.fasta
    bwa mem -t ${task.cpus} -a assembly_local.fasta ${r1} > alignments_1.sam
    bwa mem -t ${task.cpus} -a assembly_local.fasta ${r2} > alignments_2.sam
    rm assembly_local.fasta assembly_local.fasta.amb assembly_local.fasta.ann \
        assembly_local.fasta.bwt assembly_local.fasta.pac assembly_local.fasta.sa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$(bwa 2>&1 | grep -E '^Version' | sed 's/Version: //')
    END_VERSIONS
    """

    stub:
    """
    touch alignments_1.sam
    touch alignments_2.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: 0.7.19
    END_VERSIONS
    """
}
