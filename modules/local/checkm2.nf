/*
========================================================================================
    CHECKM2 - Assembly Completeness and Contamination Assessment
========================================================================================
    CheckM2 predicts the completeness and contamination of genome assemblies

    Container: oras://ghcr.io/talasjudit/bsup-2555/checkm2:1.1.0-1
    Documentation: https://github.com/chklovski/CheckM2

    TODO: Implement checkm2 command in Phase 2+
========================================================================================
*/

process CHECKM2 {
    tag "$meta.id"

    container "${params.singularity_cachedir}/checkm2-1.1.0.sif"
    publishDir "${params.outdir}/qc/checkm2", mode: 'copy'

    input:
    tuple val(meta), path(assembly)  // assembly = unicycler.fasta

    output:
    tuple val(meta), path('*_checkm2_summary.tsv'), emit: report
    tuple val(meta), path('*.log')                , emit: log
    path 'versions.yml'                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # Create temp directory for input (CheckM2 needs directory input)
    mkdir -p tmp_input
    cp ${assembly} tmp_input/${prefix}.fasta

    checkm2 predict \\
        --threads ${task.cpus} \\
        --input tmp_input \\
        --output-directory ${prefix}_checkm2 \\
        --extension fasta \\
        --force \\
        ${args}

    # Format output summary (mimicking SLURM script logic)
    # Add sample name to the report
    echo -e "sample\\t\$(head -n1 ${prefix}_checkm2/quality_report.tsv)" > ${prefix}_checkm2_summary.tsv
    tail -n+2 ${prefix}_checkm2/quality_report.tsv | \\
        sed "s/^/${prefix}\\t/" >> ${prefix}_checkm2_summary.tsv

    mv ${prefix}_checkm2/checkm2.log ${prefix}_checkm2.log
    
    # Capture version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: \$(checkm2 --version 2>&1 | sed 's/checkm2: version //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_checkm2
    touch ${prefix}_checkm2_summary.tsv
    touch ${prefix}_checkm2.log
    touch versions.yml
    """
}
