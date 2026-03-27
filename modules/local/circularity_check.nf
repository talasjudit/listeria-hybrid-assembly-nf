/*
========================================================================================
    CIRCULARITY_CHECK - Assembly Circularity Report
========================================================================================
    Checks whether assembled contigs are circular and flags any large linear contigs
    (>= 500 kb, i.e. chromosome-sized).

    Auto-detects input format from file content:

      Unicycler FASTA  : headers contain circular=true/false
                         Output: SAMPLE_unicycler_circularity.tsv

      Flye assembly_info.txt : tab-separated, col 4 = circ (Y/N)
                         Output: SAMPLE_flye_draft_circularity.tsv

    Output format: TSV (tab-separated, human-readable and MultiQC-compatible)
      Columns: sample, source, contig, length_bp, circular
      Final line: # Status: PASSED  or  # Status: WARNING - N large contig(s) ...

    Called from main workflow per assembly mode:

      unicycler        : CIRCULARITY_CHECK(ch_raw_assembly)
                         --> SAMPLE_unicycler_circularity.tsv

      flye_unicycler   : CIRCULARITY_CHECK(ch_flye_info.mix(ch_raw_assembly))
                         --> SAMPLE_flye_draft_circularity.tsv
                         --> SAMPLE_unicycler_circularity.tsv

      flye_polypolish  : CIRCULARITY_CHECK(ch_flye_info)
                         --> SAMPLE_flye_draft_circularity.tsv

    Container: seqkit (standard bash/awk available in container)
========================================================================================
*/

process CIRCULARITY_CHECK {
    tag "$meta.id"
    label 'process_low'

    container "${params.singularity_cachedir}/seqkit-2.12.0.sif"

    publishDir "${params.outdir}/qc/${params.assembly_mode}/circularity", mode: 'copy'

    input:
    tuple val(meta), path(circularity_source)

    output:
    tuple val(meta), path("*_circularity_mqc.tsv"), emit: report
    path 'versions.yml'                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    if grep -q "circular=" ${circularity_source} 2>/dev/null; then
        # Unicycler FASTA: parse circular=true/false from contig headers
        REPORT_FILE="${prefix}_unicycler_circularity_mqc.tsv"

        {
            printf "# id: 'circularity_check'\\n"
            printf "# section_name: 'Assembly Circularity'\\n"
            printf "# description: 'Circularity of assembled contigs. PASSED = all chromosome-sized contigs (>=500 kb) circular.'\\n"
            printf "# plot_type: 'table'\\n"
            printf "sample\\tsource\\tcontig\\tlength_bp\\tcircular\\n"
            grep "^>" ${circularity_source} | awk '{
                name = substr(\$1, 2)
                len = "?"; circ = "?"
                for (i = 1; i <= NF; i++) {
                    if (\$i ~ /^length=/)   { split(\$i, a, "="); len  = a[2] }
                    if (\$i ~ /^circular=/) { split(\$i, b, "="); circ = b[2] }
                }
                printf "${prefix} (unicycler)\\tunicycler\\t%s\\t%s\\t%s\\n", name, len, (circ == "true" ? "CIRCULAR" : "LINEAR")
            }'
        } > "\${REPORT_FILE}"

        N_LINEAR=\$(grep "^>" ${circularity_source} | awk '{
            len = 0; circ = "?"
            for (i = 1; i <= NF; i++) {
                if (\$i ~ /^length=/)   { split(\$i, a, "="); len  = a[2] }
                if (\$i ~ /^circular=/) { split(\$i, b, "="); circ = b[2] }
            }
            if (circ != "true" && len + 0 >= 500000) print \$0
        }' | wc -l)

    else
        # Flye assembly_info.txt: col 1=name, 2=length, 4=circ (Y/N)
        REPORT_FILE="${prefix}_flye_draft_circularity_mqc.tsv"

        {
            printf "# id: 'circularity_check'\\n"
            printf "# section_name: 'Assembly Circularity'\\n"
            printf "# description: 'Circularity of assembled contigs. PASSED = all chromosome-sized contigs (>=500 kb) circular.'\\n"
            printf "# plot_type: 'table'\\n"
            printf "sample\\tsource\\tcontig\\tlength_bp\\tcircular\\n"
            awk 'NR > 1 {
                printf "${prefix} (flye_draft)\\tflye_draft\\t%s\\t%s\\t%s\\n", \$1, \$2, (\$4 == "Y" ? "CIRCULAR" : "LINEAR")
            }' ${circularity_source}
        } > "\${REPORT_FILE}"

        N_LINEAR=\$(awk 'NR > 1 && \$4 != "Y" && \$2 + 0 >= 500000' ${circularity_source} | wc -l)
    fi

    if [ "\${N_LINEAR}" -gt 0 ]; then
        echo "# Status: WARNING - \${N_LINEAR} large contig(s) are not circularised" >> "\${REPORT_FILE}"
    else
        echo "# Status: PASSED" >> "\${REPORT_FILE}"
    fi

    cat "\${REPORT_FILE}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -n1 | sed 's/GNU bash, version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_unicycler_circularity_mqc.tsv
    touch ${prefix}_flye_draft_circularity_mqc.tsv
    touch versions.yml
    """
}
