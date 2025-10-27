/*
========================================================================================
    QUAST - Assembly Quality Assessment
========================================================================================
    QUAST evaluates genome assemblies and produces comprehensive statistics

    Key features:
    - Extensive assembly statistics (N50, L50, contig counts, etc.)
    - HTML and TSV reports
    - Can compare multiple assemblies
    - No reference genome needed for basic statistics

    Container: oras://ghcr.io/talasjudit/bsup-2555/quast:5.3.0-1
    Documentation: https://github.com/ablab/quast

    TODO: Implement quast command in Phase 2+
========================================================================================
*/

process QUAST {
    tag "$meta.id"

    container "${params.singularity_cachedir}/quast-5.3.0.sif"

    input:
    tuple val(meta), path(assembly)  // assembly = unicycler.fasta

    output:
    tuple val(meta), path('*/report.tsv'), emit: report
    tuple val(meta), path('*/report.html'), emit: html
    tuple val(meta), path('*.log')        , emit: log
    path 'versions.yml'                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO Phase 2: Implement quast command
    // Expected input:
    //   - assembly = unicycler.fasta (genome assembly to assess)
    //
    // Expected outputs:
    //   - ${prefix}_quast/report.tsv (assembly statistics in TSV format)
    //   - ${prefix}_quast/report.html (interactive HTML report)
    //   - ${prefix}_quast.log (log file)
    //
    // Key parameters to include:
    //   ${assembly} : Input assembly file
    //   --output-dir ${prefix}_quast : Output directory
    //   --threads ${task.cpus} : Use allocated CPUs
    //   --min-contig 500 : Minimum contig length to consider
    //   ${args} : Additional user-specified arguments
    //
    // Additional options to consider:
    //   --fast : Faster mode (skip some analyses)
    //   --no-plots : Don't generate plots (faster)
    //   --circos : Generate Circos plots (requires reference)
    //   --glimmer : Gene prediction with GlimmerHMM
    //   --scaffolds : Assembly is scaffolds (vs contigs)
    //
    // For reference-based analysis (optional):
    //   --reference ref.fasta : Compare against reference genome
    //   --features ref.gff : Use reference annotations
    //
    // Output files include:
    //   - report.tsv : Tab-separated metrics
    //   - report.html : Interactive HTML report
    //   - transposed_report.tsv : Alternative format
    //   - icarus.html : Contig browser
    //
    // Key metrics reported:
    //   - Number of contigs
    //   - Total length
    //   - N50, N75, L50, L75
    //   - Largest contig
    //   - GC content
    //   - N's per 100 kbp
    //
    // Log capture:
    //   Redirect stdout/stderr to ${prefix}_quast.log

    """
    # TODO: Implement quast command here

    echo "TODO: Run quast on ${assembly}"
    echo "TODO: Generate assembly statistics"
    echo "TODO: Output TSV report to ${prefix}_quast/report.tsv"
    echo "TODO: Output HTML report to ${prefix}_quast/report.html"
    echo "TODO: Save log to ${prefix}_quast.log"

    # Placeholder commands - remove this in Phase 2
    mkdir -p ${prefix}_quast
    touch ${prefix}_quast/report.tsv
    touch ${prefix}_quast/report.html
    touch ${prefix}_quast.log

    # Version capture - TODO: Update with actual quast version command
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/QUAST v//g' || echo "version_unavailable")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_quast
    touch ${prefix}_quast/report.tsv
    touch ${prefix}_quast/report.html
    touch ${prefix}_quast.log
    touch versions.yml
    """
}
