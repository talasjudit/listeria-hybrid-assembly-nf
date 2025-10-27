/*
========================================================================================
    MULTIQC - Aggregate QC Report
========================================================================================
    MultiQC aggregates results from multiple tools into a single HTML report

    Key features:
    - Collects logs and reports from all pipeline tools
    - Creates interactive visualizations
    - Supports many bioinformatics tools
    - Customizable with config file

    Container: oras://ghcr.io/talasjudit/bsup-2555/multiqc:1.31-1
    Documentation: https://multiqc.info/

    TODO: Implement multiqc command in Phase 2+
========================================================================================
*/

process MULTIQC {
    tag "aggregated_report"

    container "${params.singularity_cachedir}/multiqc-1.31.sif"

    input:
    path(multiqc_files)     // All QC files to aggregate (collected)
    path(multiqc_config)    // MultiQC configuration file

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_data'        , emit: data
    path 'versions.yml'        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    // TODO Phase 2: Implement multiqc command
    // Expected inputs:
    //   - multiqc_files = all QC files from the pipeline (fastp, quast, checkm2, etc.)
    //   - multiqc_config = assets/multiqc_config.yaml
    //
    // Expected outputs:
    //   - multiqc_report.html (interactive HTML report)
    //   - multiqc_data/ (directory with raw data and plots)
    //
    // Key parameters to include:
    //   . : Analyze files in current directory
    //   --config ${multiqc_config} : Use custom config file
    //   --title "${params.multiqc_title}" : Report title
    //   --force : Overwrite existing report
    //   --filename multiqc_report.html : Output filename
    //   ${args} : Additional user-specified arguments
    //
    // Additional options to consider:
    //   --zip-data-dir : Compress data directory
    //   --export : Export plots as files
    //   --verbose : Increase verbosity
    //   --dirs : Search subdirectories
    //   --fullnames : Don't clean sample names
    //
    // Note: MultiQC automatically detects and parses:
    //   - fastp JSON reports
    //   - QUAST TSV reports
    //   - Various log files
    //   - Custom data can be added via config file
    //
    // The multiqc_files input should be collected in main.nf:
    //   ch_qc_reports = Channel.empty()
    //       .mix(FASTP.out.json, FASTP.out.html)
    //       .mix(QUAST.out.report, QUAST.out.html)
    //       .mix(CHECKM2.out.report)
    //       .collect()
    //
    // MultiQC will:
    //   1. Search through all input files
    //   2. Identify tool outputs automatically
    //   3. Parse and aggregate results
    //   4. Generate interactive HTML report
    //   5. Create data directory with raw values

    """
    # TODO: Implement multiqc command here

    echo "TODO: Run multiqc on all collected QC files"
    echo "TODO: Use config file: ${multiqc_config}"
    echo "TODO: Set report title: ${params.multiqc_title}"
    echo "TODO: Generate multiqc_report.html"
    echo "TODO: Create multiqc_data/ directory with raw data"

    # Placeholder commands - remove this in Phase 2
    touch multiqc_report.html
    mkdir -p multiqc_data
    touch multiqc_data/multiqc_data.json

    # Version capture - TODO: Update with actual multiqc version command
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version 2>&1 | sed 's/multiqc, version //g' || echo "version_unavailable")
    END_VERSIONS
    """

    stub:
    """
    touch multiqc_report.html
    mkdir multiqc_data
    touch multiqc_data/multiqc_data.json
    touch versions.yml
    """
}
