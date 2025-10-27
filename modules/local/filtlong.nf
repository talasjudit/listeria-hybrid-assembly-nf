/*
========================================================================================
    FILTLONG - Nanopore Read Quality Filtering
========================================================================================
    Filtlong filters long reads by quality, keeping only the best subset

    Key features:
    - Quality-based filtering
    - Length-based filtering
    - Can use Illumina reads as reference for quality assessment
    - Removes worst-quality reads to improve assembly

    Container: oras://ghcr.io/talasjudit/bsup-2555/filtlong:0.3.0-1
    Documentation: https://github.com/rrwick/Filtlong

    TODO: Implement filtlong command in Phase 2+
========================================================================================
*/

process FILTLONG {
    tag "$meta.id"

    container "${params.singularity_cachedir}/filtlong-0.3.0.sif"

    input:
    tuple val(meta), path(reads)  // reads = nanopore_porechop.fastq.gz

    output:
    tuple val(meta), path('*_filtlong.fastq.gz'), emit: reads
    tuple val(meta), path('*.log')               , emit: log
    path 'versions.yml'                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO Phase 2: Implement filtlong command
    // Expected input:
    //   - reads = nanopore_porechop.fastq.gz (adapter-trimmed Nanopore reads)
    //
    // Expected outputs:
    //   - ${prefix}_filtlong.fastq.gz (quality-filtered Nanopore reads)
    //   - ${prefix}_filtlong.log (log file with filtering statistics)
    //
    // Key parameters to include:
    //   --min_length ${params.min_read_length} : Minimum read length (default: 6000)
    //   --keep_percent ${params.filtlong_keep_percent} : Keep best N% of reads (default: 95)
    //   ${args} : Additional user-specified arguments
    //
    // Additional options to consider:
    //   --min_mean_q 80 : Minimum mean quality score
    //   --min_window_q 70 : Minimum window quality score
    //   --length_weight 1 : Weight given to read length
    //   --mean_q_weight 1 : Weight given to mean quality
    //
    // Command structure:
    //   filtlong [options] ${reads} | gzip > ${prefix}_filtlong.fastq.gz 2> ${prefix}_filtlong.log
    //
    // Note: Filtlong outputs to stdout, so pipe to gzip for compression

    """
    # TODO: Implement filtlong command here

    echo "TODO: Run filtlong on ${reads}"
    echo "TODO: Filter reads by min_length=${params.min_read_length}"
    echo "TODO: Keep top ${params.filtlong_keep_percent}% of reads by quality"
    echo "TODO: Output filtered reads to ${prefix}_filtlong.fastq.gz"
    echo "TODO: Save filtering statistics to ${prefix}_filtlong.log"

    # Placeholder command - remove this in Phase 2
    touch ${prefix}_filtlong.fastq.gz
    touch ${prefix}_filtlong.log

    # Version capture - TODO: Update with actual filtlong version command
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filtlong: \$(filtlong --version 2>&1 | sed 's/Filtlong v//g' || echo "version_unavailable")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_filtlong.fastq.gz
    touch ${prefix}_filtlong.log
    touch versions.yml
    """
}
