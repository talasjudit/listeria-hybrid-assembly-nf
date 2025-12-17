/*
========================================================================================
    QUAST - Assembly Quality Assessment
========================================================================================
    QUAST evaluates genome assemblies and produces comprehensive statistics

    Container: oras://ghcr.io/talasjudit/bsup-2555/quast:5.3.0-1
    Documentation: https://github.com/ablab/quast

========================================================================================
*/

process QUAST {
    tag "$meta.id"

    container "${params.singularity_cachedir}/quast-5.3.0.sif"
    publishDir "${params.outdir}/qc/quast", mode: 'copy'

    input:
    tuple val(meta), path(assembly)  // assembly = unicycler.fasta

    output:
    tuple val(meta), path('*_quast_summary.tsv'), emit: report
    tuple val(meta), path('*_quast')            , emit: dir
    tuple val(meta), path('*/report.html')      , emit: html
    tuple val(meta), path('*/icarus.html')      , emit: icarus
    tuple val(meta), path('*.log')              , emit: log
    path 'versions.yml'                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    quast.py \\
        ${assembly} \\
        --output-dir ${prefix}_quast \\
        --threads ${task.cpus} \\
        --min-contig 500 \\
        ${args}

    # Format output summary (mimicking SLURM script logic)
    # Create a simplified summary with sample name
    echo -e "sample\\t\$(head -n1 ${prefix}_quast/transposed_report.tsv | cut -f2-)" > ${prefix}_quast_summary.tsv
    tail -n+2 ${prefix}_quast/transposed_report.tsv | \\
        sed "s/^/${prefix}\\t/" >> ${prefix}_quast_summary.tsv

    mv ${prefix}_quast/quast.log ${prefix}_quast.log

    # Capture version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/QUAST v//g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_quast
    touch ${prefix}_quast_summary.tsv
    touch ${prefix}_quast/report.html
    touch ${prefix}_quast/icarus.html
    touch ${prefix}_quast.log
    touch versions.yml
    """
}
