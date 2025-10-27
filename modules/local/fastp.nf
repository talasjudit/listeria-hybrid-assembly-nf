/*
========================================================================================
    FASTP - Illumina Read QC and Trimming
========================================================================================
    fastp performs quality control and trimming of Illumina paired-end reads

    Key features:
    - Automatic adapter detection and removal
    - Quality filtering
    - Base correction for overlapping paired reads
    - HTML and JSON QC reports

    Container: oras://ghcr.io/talasjudit/bsup-2555/fastp:1.0.1-1
    Documentation: https://github.com/OpenGene/fastp

    TODO: Implement fastp command in Phase 2+
========================================================================================
*/

process FASTP {
    tag "$meta.id"

    container "${params.singularity_cachedir}/fastp-1.0.1.sif"

    input:
    tuple val(meta), path(reads)  // reads = [R1.fastq.gz, R2.fastq.gz]

    output:
    tuple val(meta), path('*_trimmed.fastq.gz'), emit: reads
    tuple val(meta), path('*.json')             , emit: json
    tuple val(meta), path('*.html')             , emit: html
    path 'versions.yml'                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO Phase 2: Implement fastp command
    // Expected inputs:
    //   - reads[0] = R1.fastq.gz (forward reads)
    //   - reads[1] = R2.fastq.gz (reverse reads)
    //
    // Expected outputs:
    //   - ${prefix}_R1_trimmed.fastq.gz (trimmed forward reads)
    //   - ${prefix}_R2_trimmed.fastq.gz (trimmed reverse reads)
    //   - ${prefix}.json (QC metrics in JSON format)
    //   - ${prefix}.html (QC report in HTML format)
    //
    // Key parameters to include:
    //   --detect_adapter_for_pe : Auto-detect adapters for paired-end
    //   --correction : Enable base correction for overlapping read pairs
    //   --qualified_quality_phred 20 : Minimum quality score
    //   --thread ${task.cpus} : Use allocated CPUs
    //   --json ${prefix}.json : Output JSON report
    //   --html ${prefix}.html : Output HTML report
    //   --in1 ${reads[0]} : Input forward reads
    //   --in2 ${reads[1]} : Input reverse reads
    //   --out1 ${prefix}_R1_trimmed.fastq.gz : Output forward reads
    //   --out2 ${prefix}_R2_trimmed.fastq.gz : Output reverse reads
    //
    // Additional options to consider:
    //   --length_required 50 : Minimum read length after trimming
    //   --cut_front / --cut_tail : Additional quality trimming
    //   ${args} : Additional user-specified arguments

    """
    # TODO: Implement fastp command here

    echo "TODO: Run fastp on ${reads[0]} and ${reads[1]}"
    echo "TODO: Output trimmed reads to ${prefix}_R1_trimmed.fastq.gz and ${prefix}_R2_trimmed.fastq.gz"

    # Placeholder command - remove this in Phase 2
    touch ${prefix}_R1_trimmed.fastq.gz
    touch ${prefix}_R2_trimmed.fastq.gz
    touch ${prefix}.json
    touch ${prefix}.html

    # Version capture - TODO: Update with actual fastp version command
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed 's/fastp //g' || echo "version_unavailable")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_R1_trimmed.fastq.gz
    touch ${prefix}_R2_trimmed.fastq.gz
    touch ${prefix}.json
    touch ${prefix}.html
    touch versions.yml
    """
}
