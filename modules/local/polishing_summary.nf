/*
========================================================================================
    POLISHING_SUMMARY - Before/After Polishing Comparison (dnadiff)
========================================================================================
    Compares two dnadiff reports (Flye draft vs Polypolish output, both vs the same
    reference) and produces a per-sample summary TSV with IMPROVED / UNCHANGED / WORSE
    status.

    Status logic:
      IMPROVED  — total variants (SNPs + indels) decreased after polishing
      UNCHANGED — no change in total variant count
      WORSE     — total variants increased after polishing

    Only runs when:
      - params.assembly_mode == 'flye_polypolish'
      - params.reference is provided

    Input: joined channel from DNADIFF_DRAFT.out.report + DNADIFF_POLISHED.out.report
      tuple val(meta), path(draft_report), path(polished_report)

    Output format: TSV with embedded MultiQC custom content headers
      Columns: Sample, Avg Identity (draft), Avg Identity (polished),
               SNPs (draft), SNPs (polished), Indels (draft), Indels (polished), Status
      Final comment: # Status: IMPROVED / UNCHANGED / WORSE

    Container: seqkit (bash + awk available)
    Published to: qc/dnadiff/
========================================================================================
*/

process POLISHING_SUMMARY {
    tag "$meta.id"
    label 'process_single'

    container "${params.singularity_cachedir}/seqkit-2.12.0.sif"

    publishDir "${params.outdir}/qc/flye_polypolish/dnadiff", mode: 'copy'

    input:
    tuple val(meta), path(draft_report, stageAs: 'draft_*'), path(polished_report, stageAs: 'polished_*')

    output:
    tuple val(meta), path("*_polishing_summary_mqc.tsv"), emit: summary
    path 'versions.yml'                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Extract metrics from Flye draft report
    draft_id=\$(grep "^AvgIdentity"  ${draft_report} | head -1 | awk '{print \$2}')
    draft_snps=\$(grep "^TotalSNPs"  ${draft_report} | awk '{print \$2}')
    draft_indels=\$(grep "^TotalIndels" ${draft_report} | awk '{print \$2}')

    # Extract metrics from Polypolish report
    polish_id=\$(grep "^AvgIdentity"  ${polished_report} | head -1 | awk '{print \$2}')
    polish_snps=\$(grep "^TotalSNPs"  ${polished_report} | awk '{print \$2}')
    polish_indels=\$(grep "^TotalIndels" ${polished_report} | awk '{print \$2}')

    # Determine status: compare total variant counts (SNPs + indels)
    draft_total=\$(( \${draft_snps} + \${draft_indels} ))
    polish_total=\$(( \${polish_snps} + \${polish_indels} ))
    if   [ "\${polish_total}" -lt "\${draft_total}" ]; then STATUS="IMPROVED"
    elif [ "\${polish_total}" -eq "\${draft_total}" ]; then STATUS="UNCHANGED"
    else                                                    STATUS="WORSE"
    fi

    # Write MultiQC-compatible TSV with embedded headers
    printf "# id: 'polishing_summary'\\n"                                                                                                                 > ${prefix}_polishing_summary_mqc.tsv
    printf "# section_name: 'Polishing Summary'\\n"                                                                                                      >> ${prefix}_polishing_summary_mqc.tsv
    printf "# description: 'Before/after Polypolish polishing vs reference. IMPROVED = fewer total variants (SNPs+indels) after polishing.'\\n"          >> ${prefix}_polishing_summary_mqc.tsv
    printf "# plot_type: 'table'\\n"                                                                                                                      >> ${prefix}_polishing_summary_mqc.tsv
    printf "Sample\\tAvg Identity (draft)\\tAvg Identity (polished)\\tSNPs (draft)\\tSNPs (polished)\\tIndels (draft)\\tIndels (polished)\\tStatus\\n"   >> ${prefix}_polishing_summary_mqc.tsv
    printf "%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n" \
        "${prefix}" "\${draft_id}" "\${polish_id}" \
        "\${draft_snps}" "\${polish_snps}" \
        "\${draft_indels}" "\${polish_indels}" \
        "\${STATUS}"                                                                                                                                       >> ${prefix}_polishing_summary_mqc.tsv
    printf "# Status: \${STATUS}\\n"                                                                                                                      >> ${prefix}_polishing_summary_mqc.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -n1 | sed 's/GNU bash, version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_polishing_summary_mqc.tsv
    touch versions.yml
    """
}