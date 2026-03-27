/*
========================================================================================
    DNADIFF - Assembly-vs-Reference Comparison (MUMmer)
========================================================================================
    dnadiff compares an assembled genome against a reference using MUMmer alignments.
    It reports SNPs, indels, rearrangements, and overall sequence identity.

    Only runs when:
      - params.assembly_mode == 'flye_polypolish'
      - params.reference is provided

    The reference FASTA is supplied via --reference and broadcast to all samples as a
    Nextflow value channel (one reference, many assemblies).

    Container: mummer4-4.0.1.sif
    Documentation: https://github.com/mummer4/mummer
========================================================================================
*/

process DNADIFF {
    tag "$meta.id"

    container "${params.singularity_cachedir}/mummer4-4.0.1.sif"

    publishDir "${params.outdir}/qc/flye_polypolish/dnadiff", mode: 'copy'

    input:
    tuple val(meta), path(assembly)
    path(reference)
    // reference is broadcast via Channel.value() - same file used for all samples

    output:
    tuple val(meta), path("*.report")         , emit: report
    tuple val(meta), path("*.delta")          , emit: delta
    tuple val(meta), path("*.snps")           , emit: snps, optional: true
    tuple val(meta), path("*_dnadiff_mqc.tsv"), emit: mqc
    path 'versions.yml'                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    dnadiff -p ${prefix} ${args} ${reference} ${assembly}
    
    # Remove derived delta files to avoid *.delta glob matching them
    rm -f ${prefix}.1delta ${prefix}.mdelta

    # Extract key metrics for MultiQC custom table
    avg_id=\$(grep "^AvgIdentity" ${prefix}.report | head -1 | awk '{print \$2}')
    aligned_qry=\$(grep "^AlignedBases" ${prefix}.report | awk '{split(\$3,a,"[()%]"); print a[2]}')
    total_snps=\$(grep "^TotalSNPs" ${prefix}.report | awk '{print \$2}')
    total_indels=\$(grep "^TotalIndels" ${prefix}.report | awk '{print \$2}')
    printf "# id: 'dnadiff_%s'\\n" "${prefix}"                                                                                   > ${prefix}_dnadiff_mqc.tsv
    printf "# section_name: 'Reference Comparison (dnadiff)'\\n"                                                                >> ${prefix}_dnadiff_mqc.tsv
    printf "# description: 'Assembly vs reference comparison (flye_polypolish mode). Sequence identity and variant counts.'\\n" >> ${prefix}_dnadiff_mqc.tsv
    printf "# plot_type: 'table'\\n"                                                                                             >> ${prefix}_dnadiff_mqc.tsv
    printf "Sample\\tAvg Identity (%%)\\tAligned QRY (%%)\\tTotal SNPs\\tTotal Indels\\n"                                       >> ${prefix}_dnadiff_mqc.tsv
    printf "%s\\t%s\\t%s\\t%s\\t%s\\n" "${prefix}" "\${avg_id}" "\${aligned_qry}" "\${total_snps}" "\${total_indels}"           >> ${prefix}_dnadiff_mqc.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dnadiff: \$(dnadiff --version 2>&1 | grep -v "^WARNING:" | grep -oE '[0-9]+\\.[0-9]+' | head -1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.report
    touch ${prefix}.delta
    touch ${prefix}.snps
    touch ${prefix}_dnadiff_mqc.tsv
    touch versions.yml
    """
}
