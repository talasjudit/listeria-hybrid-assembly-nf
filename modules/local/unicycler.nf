/*
========================================================================================
    UNICYCLER - Hybrid Assembly
========================================================================================
    Unicycler assembles bacterial genomes using both short and long reads.
    Supports optional existing assembly (e.g., from Flye) via the assembly input.

    Container: docker://quay.io/biocontainers/unicycler:0.5.1--py39h746d604_5
    Documentation: https://github.com/rrwick/Unicycler
========================================================================================
*/

process UNICYCLER {
    tag "$meta.id"

    container "${params.singularity_cachedir}/unicycler-0.5.1.sif"

    publishDir "${params.outdir}/assembly/unicycler", mode: 'copy'

    input:
    tuple val(meta), path(illumina_reads), path(nanopore_reads), path(assembly)
    // assembly: Optional Flye assembly (or empty list [])

    output:
    tuple val(meta), path('*_unicycler.fasta')    , emit: assembly
    tuple val(meta), path('*_unicycler_graph.gfa'), emit: gfa
    tuple val(meta), path('*.log')                , emit: process_log
    path 'versions.yml'                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    // Check if optional assembly is provided
    def assembly_arg = assembly ? "--existing_long_read_assembly ${assembly}" : ""

    """
    unicycler \\
        -1 ${illumina_reads[0]} \\
        -2 ${illumina_reads[1]} \\
        -l ${nanopore_reads} \\
        -o out_dir \\
        --threads ${task.cpus} \\
        --verbosity 2 \\
        ${assembly_arg} \\
        ${args}

    # Rename and move outputs
    mv out_dir/assembly.fasta ${prefix}_unicycler.fasta
    mv out_dir/assembly.gfa ${prefix}_unicycler_graph.gfa
    mv out_dir/unicycler.log ${prefix}_unicycler.log
    
    # Capture version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        unicycler: \$(unicycler --version 2>&1 | sed 's/Unicycler v//g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_unicycler
    touch ${prefix}_unicycler.fasta
    touch ${prefix}_unicycler_graph.gfa
    touch ${prefix}_unicycler.log
    touch versions.yml
    """
}
