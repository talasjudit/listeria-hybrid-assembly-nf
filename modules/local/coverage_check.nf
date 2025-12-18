/*
========================================================================================
    COVERAGE_CHECK - Minimum Data Quality Gate
========================================================================================
    Validates that samples have sufficient sequencing coverage before assembly.
    
    Container: Uses seqkit for fast sequence statistics
    Documentation: https://bioinf.shenwei.me/seqkit/
========================================================================================
*/

process COVERAGE_CHECK {
    tag "$meta.id"
    label 'process_low' 
    
    publishDir "${params.outdir}/qc/coverage", mode: 'copy', pattern: "*_coverage_report.txt"

    // Using seqkit for stats calculation
    container "${params.singularity_cachedir}/seqkit-2.12.0.sif"

    input:
    tuple val(meta), path(illumina_reads), path(nanopore_reads)

    output:
    // Emit all samples (passed and failed) along with the report
    tuple val(meta), path(illumina_reads), path(nanopore_reads), path("*_coverage_report.txt"), emit: results
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    // Convert e.g., "3m" -> 3000000 for calculation
    """
    # 1. Parse Genome Size (handle "3m" format)
    GENOME_SIZE=\$(echo "${params.genome_size}" | sed 's/[mM]/*1000000/' | sed 's/[kK]/*1000/' | bc)
    
    echo "Genome Size: \$GENOME_SIZE bp"

    # 2. Calculate Illumina Coverage (R1 + R2)
    # sum column 5 (sum_len) of all input files, skipping header
    ILLUMINA_BASES=\$(seqkit stats -T ${illumina_reads} | awk 'NR>1 {sum+=\$5} END {print int(sum)}')
    ILLUMINA_COV=\$(echo "scale=2; \$ILLUMINA_BASES / \$GENOME_SIZE" | bc)
    
    echo "Illumina Bases: \$ILLUMINA_BASES"
    echo "Illumina Coverage: \${ILLUMINA_COV}x"

    # 3. Calculate Nanopore Coverage
    NANOPORE_BASES=\$(seqkit stats -T ${nanopore_reads} | awk 'NR>1 {sum+=\$5} END {print int(sum)}')
    NANOPORE_COV=\$(echo "scale=2; \$NANOPORE_BASES / \$GENOME_SIZE" | bc)
    
    echo "Nanopore Bases: \$NANOPORE_BASES"
    echo "Nanopore Coverage: \${NANOPORE_COV}x"

    # 4. Generate Report
    echo "Sample: ${meta.id}" > ${prefix}_coverage_report.txt
    echo "Genome Size: \$GENOME_SIZE" >> ${prefix}_coverage_report.txt
    echo "Illumina Coverage: \${ILLUMINA_COV}x (Threshold: ${params.min_illumina_coverage}x)" >> ${prefix}_coverage_report.txt
    echo "Nanopore Coverage: \${NANOPORE_COV}x (Threshold: ${params.min_nanopore_coverage}x)" >> ${prefix}_coverage_report.txt

    # 5. Check Thresholds (Fail logic)
    # Using bc for float comparison. Returns 1 if true.
    ILLUMINA_FAIL=\$(echo "\$ILLUMINA_COV < ${params.min_illumina_coverage}" | bc)
    NANOPORE_FAIL=\$(echo "\$NANOPORE_COV < ${params.min_nanopore_coverage}" | bc)

    FAILURE=0
    
    if [ "\$ILLUMINA_FAIL" -eq 1 ]; then
        echo "FAIL: Illumina coverage (\${ILLUMINA_COV}x) is below minimum threshold (${params.min_illumina_coverage}x)"
        echo "Reason: Low Illumina coverage (\${ILLUMINA_COV}x < ${params.min_illumina_coverage}x)" >> ${prefix}_coverage_report.txt
        FAILURE=1
    fi

    if [ "\$NANOPORE_FAIL" -eq 1 ]; then
        echo "FAIL: Nanopore coverage (\${NANOPORE_COV}x) is below minimum threshold (${params.min_nanopore_coverage}x)"
        echo "Reason: Low Nanopore coverage (\${NANOPORE_COV}x < ${params.min_nanopore_coverage}x)" >> ${prefix}_coverage_report.txt
        FAILURE=1
    fi

    if [ "\$FAILURE" -eq 1 ]; then
        echo "Status: FAILED" >> ${prefix}_coverage_report.txt
    else
        echo "PASS: Coverage checks passed."
        echo "Status: PASSED" >> ${prefix}_coverage_report.txt
    fi

    # 6. Versions
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version | sed 's/seqkit v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_coverage_report.txt
    touch versions.yml
    """
}