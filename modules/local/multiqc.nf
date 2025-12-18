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

========================================================================================
*/

process MULTIQC {
    tag "aggregated_report"

    container "${params.singularity_cachedir}/multiqc-1.31.sif"

    input:
    path(multiqc_files)     // All QC files to aggregate (collected)
    path(multiqc_config)    // MultiQC configuration file

    output:
    path 'multiqc_report.html'      , emit: report
    path 'multiqc_report_data'      , emit: data
    path 'versions.yml'             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def config_arg = multiqc_config ? "--config ${multiqc_config}" : ''
    def title_arg = params.multiqc_title ? "--title \"${params.multiqc_title}\"" : ''
    def custom_title_arg = args.contains('--title') ? '' : title_arg // Avoid duplicate title

    """
    multiqc . \\
        ${config_arg} \\
        ${custom_title_arg} \\
        --filename multiqc_report.html \\
        --force \\
        ${args}

    # Version capture (robust handling)
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version 2>&1 | sed 's/multiqc, version //g' | sed 's/multiqc, //g' | awk '{print \$NF}')
    END_VERSIONS
    """

    stub:
    """
    touch multiqc_report.html
    mkdir multiqc_report_data
    touch multiqc_report_data/multiqc_data.json
    touch versions.yml
    """
}
