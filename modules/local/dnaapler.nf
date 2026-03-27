/*
========================================================================================
    DNAAPLER - Chromosome Reorientation to dnaA
========================================================================================
    dnaapler reorients completed circular microbial assemblies so that they begin
    with the dnaA gene (chromosomes), repA (plasmids), or terL (phage).

    The 'all' subcommand is used here: it handles mixed contig files containing
    chromosomes, plasmids, and/or phage sequences without requiring prior classification.
    Only truly circular sequences are reoriented; linear contigs are left unchanged.

    Applied to ALL assembly modes (unicycler, flye_unicycler, flye_polypolish) for
    consistent output orientation across the pipeline.

    Documentation: https://github.com/gbouras13/dnaapler
========================================================================================
*/

process DNAAPLER {
    tag "$meta.id"

    container "${params.singularity_cachedir}/dnaapler-1.3.0.sif"

    publishDir "${params.outdir}/assembly/${params.assembly_mode}", mode: 'copy'

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*_dnaapler.fasta")    , emit: assembly
    tuple val(meta), path("*_dnaapler.log")      , emit: process_log
    path 'versions.yml'                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    dnaapler all \\
        -i ${assembly} \\
        -o out_dir \\
        -p ${prefix} \\
        -t ${task.cpus} \\
        ${args} \\
        > ${prefix}_dnaapler.log 2>&1
    
        mv out_dir/${prefix}_reoriented.fasta ${prefix}_dnaapler.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dnaapler: \$(dnaapler --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_dnaapler.fasta
    touch ${prefix}_dnaapler.log
    touch versions.yml
    """
}
