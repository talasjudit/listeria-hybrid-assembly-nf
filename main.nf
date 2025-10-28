#!/usr/bin/env nextflow

/*
========================================================================================
    Hybrid Bacterial Genome Assembly Pipeline
========================================================================================
    Github: https://github.com/yourusername/listeria-hybrid-nf
    Documentation: https://github.com/yourusername/listeria-hybrid-nf/docs

    This pipeline performs hybrid bacterial genome assembly using:
    - Illumina paired-end short reads (high accuracy)
    - Nanopore long reads (high contiguity)

    Pipeline Steps:
    1. Input validation and parsing
    2. QC and trimming of Illumina reads (fastp)
    3. QC and filtering of Nanopore reads (porechop + filtlong)
    4. Optional: Long-read assembly with Flye
    5. Hybrid assembly with Unicycler (with or without Flye scaffold)
    6. Assembly quality assessment (CheckM2 + QUAST)
    7. Report aggregation (MultiQC)
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

/*
========================================================================================
    IMPORT WORKFLOWS
========================================================================================
*/

// Import the installation workflow with alias to avoid naming conflict
include { INSTALL as INSTALL_CONTAINERS } from '${projectDir}/workflows/install'

/*
========================================================================================
    PARAMETER VALIDATION & HELP
========================================================================================
*/

// Load and validate parameters using nf-schema plugin
include { validateParameters; paramsSummaryLog; samplesheetToList } from '${projectDir}/plugin/nf-schema'

// Print help message if requested
if (params.help) {
    log.info """
    ╔═══════════════════════════════════════════════════════════════╗
    ║         Hybrid Bacterial Genome Assembly Pipeline             ║
    ╚═══════════════════════════════════════════════════════════════╝

    Usage:
      # Install containers (run on login node with internet)
      nextflow run main.nf -entry INSTALL -profile singularity -resume

      # Run pipeline (can run on compute nodes)
      nextflow run main.nf --input samplesheet.csv --outdir results -profile singularity,slurm

    Required Arguments:
      --input                Path to samplesheet CSV file
      --outdir               Output directory for results

    Optional Arguments:
      --use_flye             Run Flye assembly before Unicycler [default: false]
      --genome_size          Expected genome size for Flye [default: 3m]
      --min_coverage         Minimum Illumina coverage threshold [default: 30]
      --min_read_length      Minimum Nanopore read length [default: 6000]
      --filtlong_keep_percent Keep top N% of Nanopore reads [default: 95]

    Resource Limits:
      --max_cpus             Maximum CPUs per process [default: 12]
      --max_memory           Maximum memory per process [default: 128.GB]
      --max_time             Maximum time per process [default: 24.h]

    Profiles:
      -profile singularity   Enable Singularity containers (required)
      -profile slurm         Use SLURM executor for HPC
      -profile local         Use local executor
      -profile test          Run with minimal test resources

    Entry Points:
      (default)              Run the assembly pipeline
      -entry INSTALL         Download and cache containers

    Examples:
      # 1. Install containers first (on login node)
      nextflow run main.nf -entry INSTALL -profile singularity -resume

      # 2. Basic pipeline run on SLURM
      nextflow run main.nf -profile singularity,slurm \\
        --input samplesheet.csv \\
        --outdir results

      # 3. With Flye pre-assembly
      nextflow run main.nf -profile singularity,slurm \\
        --input samplesheet.csv \\
        --outdir results \\
        --use_flye

      # 4. Local execution with custom resources
      nextflow run main.nf -profile singularity,local \\
        --input samplesheet.csv \\
        --outdir results \\
        --max_cpus 8 \\
        --max_memory 32.GB

    For more details, see: https://github.com/yourusername/listeria-hybrid-nf
    """.stripIndent()
    exit 0
}

// Print version if requested
if (params.version) {
    log.info """
    Pipeline: ${workflow.manifest.name}
    Version:  ${workflow.manifest.version}
    """.stripIndent()
    exit 0
}

/*
========================================================================================
    NAMED WORKFLOWS
========================================================================================
*/

/*
 * WORKFLOW: INSTALL
 * Download and cache all Singularity containers
 * This should be run on a node with internet access (e.g., login node)
 */
workflow INSTALL {
    INSTALL_CONTAINERS()
}

/*
 * WORKFLOW: LISTERIA_HYBRID_NF (Main Pipeline)
 * Performs hybrid bacterial genome assembly
 */
workflow LISTERIA_HYBRID_NF {
    
    // Validate input parameters against schema
    validateParameters()
    
    // Print parameter summary
    log.info paramsSummaryLog(workflow)
    
    // Check that required parameters are provided
    if (!params.input) {
        exit 1, "ERROR: --input parameter is required. Please provide a samplesheet CSV file."
    }
    
    // Check that input file exists
    if (!file(params.input).exists()) {
        exit 1, "ERROR: Input samplesheet file not found: ${params.input}"
    }

    /*
     * Print pipeline header
     */
    log.info """

    ╔═══════════════════════════════════════════════════════════════╗
    ║              Hybrid Assembly Pipeline                         ║
    ║                    Version ${workflow.manifest.version}                        ║
    ╚═══════════════════════════════════════════════════════════════╝

    Input samplesheet : ${params.input}
    Output directory  : ${params.outdir}
    Assembly mode     : ${params.use_flye ? 'Flye + Unicycler (with existing assembly)' : 'Unicycler only (standard hybrid)'}
    Genome size       : ${params.genome_size}
    """.stripIndent()

    /*
     * ========================================================================
     * STEP 1: Parse and validate samplesheet
     * ========================================================================
     * Subworkflow: INPUT_CHECK handles complex parsing and validation
     * - Reads CSV samplesheet
     * - Validates file existence and format
     * - Creates separate channels for Illumina and Nanopore reads
     */
    // TODO Phase 2: Implement samplesheet parsing
    // INPUT_CHECK(file(params.input))
    //
    // ch_illumina = INPUT_CHECK.out.illumina
    //   // Format: [meta, [R1, R2]]
    //
    // ch_nanopore = INPUT_CHECK.out.nanopore
    //   // Format: [meta, nanopore.fq.gz]

    /*
     * ========================================================================
     * STEP 2: QC Illumina reads
     * ========================================================================
     * Direct module: FASTP (single process, no need for subworkflow)
     * - Adapter detection and trimming
     * - Quality filtering
     * - Base correction for overlapping pairs
     * - Generates JSON and HTML QC reports
     */
    // TODO Phase 2: Implement Illumina QC
    // FASTP(ch_illumina)
    //
    // ch_illumina_trimmed = FASTP.out.reads
    //   // Format: [meta, [R1_trimmed, R2_trimmed]]
    //
    // // Collect QC reports for MultiQC
    // ch_qc_reports = Channel.empty()
    //     .mix(FASTP.out.json)
    //     .mix(FASTP.out.html)

    /*
     * ========================================================================
     * STEP 3: QC Nanopore reads
     * ========================================================================
     * Subworkflow: QC_NANOPORE groups two processes that always run together
     * - Porechop ABI: Remove adapters and barcodes
     * - Filtlong: Length and quality filtering
     * These are grouped because they always run sequentially on the same data
     */
    // TODO Phase 2: Implement Nanopore QC
    // QC_NANOPORE(ch_nanopore)
    //
    // ch_nanopore_filtered = QC_NANOPORE.out.reads
    //   // Format: [meta, filtered.fq.gz]
    //
    // // Add Nanopore QC logs to MultiQC collection
    // ch_qc_reports = ch_qc_reports
    //     .mix(QC_NANOPORE.out.logs)

    /*
     * ========================================================================
     * STEP 4: Optional Flye assembly (if requested)
     * ========================================================================
     * Direct module: FLYE (single process, conditional execution)
     * - Long-read assembly from filtered Nanopore reads
     * - Only runs if --use_flye is true
     * - Creates assembly that Unicycler can use as scaffold
     *
     * Conditional execution pattern:
     * - If use_flye: FLYE produces ch_flye_assembly
     * - If not: ch_flye_assembly is empty channel
     * - Unicycler handles both cases automatically
     */
    // TODO Phase 2: Implement Flye assembly
    // if (params.use_flye) {
    //     FLYE(ch_nanopore_filtered)
    //     ch_flye_assembly = FLYE.out.assembly
    //       // Format: [meta, assembly.fasta]
    //
    //     ch_qc_reports = ch_qc_reports
    //         .mix(FLYE.out.log)
    // } else {
    //     ch_flye_assembly = Channel.empty()
    // }

    /*
     * ========================================================================
     * STEP 5: Hybrid assembly with Unicycler
     * ========================================================================
     * Subworkflow: ASSEMBLY_HYBRID handles complex conditional logic
     * - Decides between standard Unicycler or Unicycler-with-Flye
     * - Hides complexity of conditional execution from main workflow
     * - Both modes produce same output structure
     *
     * Two modes:
     * 1. Standard (no Flye): Unicycler builds graph from Illumina, bridges with Nanopore
     * 2. With Flye: Uses Flye assembly as scaffold, polishes with Illumina
     */
    // TODO Phase 2: Implement hybrid assembly
    // ASSEMBLY_HYBRID(
    //     ch_illumina_trimmed,
    //     ch_nanopore_filtered,
    //     ch_flye_assembly
    // )
    //
    // ch_assemblies = ASSEMBLY_HYBRID.out.assembly
    //   // Format: [meta, assembly.fasta]
    //
    // // Add assembly logs to MultiQC collection
    // ch_qc_reports = ch_qc_reports
    //     .mix(ASSEMBLY_HYBRID.out.log)

    /*
     * ========================================================================
     * STEP 6: Assembly quality assessment
     * ========================================================================
     * Subworkflow: QC_ASSEMBLY groups two QC processes that run in parallel
     * - CheckM2: Completeness and contamination
     * - QUAST: Assembly statistics (N50, contig counts, etc.)
     * - Both analyze the same assembly simultaneously
     */
    // TODO Phase 2: Implement assembly QC
    // QC_ASSEMBLY(ch_assemblies)
    //
    // // Add assembly QC reports to MultiQC collection
    // ch_qc_reports = ch_qc_reports
    //     .mix(QC_ASSEMBLY.out.checkm2_reports)
    //     .mix(QC_ASSEMBLY.out.quast_reports)

    /*
     * ========================================================================
     * STEP 7: Aggregate QC reports with MultiQC
     * ========================================================================
     * Direct module: MULTIQC (single process)
     * - Collects all QC reports from the entire pipeline
     * - Creates single interactive HTML report
     * - Uses custom config from assets/multiqc_config.yaml
     */
    // TODO Phase 2: Implement MultiQC
    //
    // // Collect all QC reports
    // ch_multiqc_files = ch_qc_reports
    //     .collect()
    //     // Collects all files into a single list
    //
    // // Get MultiQC config file
    // ch_multiqc_config = file("${projectDir}/assets/multiqc_config.yaml", checkIfExists: true)
    //
    // // Run MultiQC
    // MULTIQC(
    //     ch_multiqc_files,
    //     ch_multiqc_config
    // )

    /*
     * ========================================================================
     * Version tracking
     * ========================================================================
     */
    // TODO Phase 2: Collect all version information
    //
    // ch_versions = Channel.empty()
    //     .mix(FASTP.out.versions)
    //     .mix(QC_NANOPORE.out.versions)
    //     .mix(FLYE.out.versions.ifEmpty([]))
    //     .mix(ASSEMBLY_HYBRID.out.versions)
    //     .mix(QC_ASSEMBLY.out.versions)
    //     .mix(MULTIQC.out.versions)
    //
    // // Could create a versions summary file here

    /*
     * Placeholder message for Phase 1
     */
    log.info """

    ╔═══════════════════════════════════════════════════════════════╗
    ║                   Phase 1 Scaffold                            ║
    ╚═══════════════════════════════════════════════════════════════╝

    This is the Phase 1 scaffold with TODOs for implementation.

    Pipeline structure is defined but processes are not yet implemented.
    See individual module and subworkflow files for implementation TODOs.

    To implement in Phase 2+:
    1. Uncomment module/subworkflow imports
    2. Uncomment workflow step implementations
    3. Remove placeholder messages
    4. Test with real data

    """.stripIndent()
}

/*
========================================================================================
    RUN MAIN WORKFLOW (DEFAULT ENTRY POINT)
========================================================================================
*/

workflow {
    LISTERIA_HYBRID_NF()
}

/*
========================================================================================
    COMPLETION HANDLERS
========================================================================================
    Note: These handlers only run for the main pipeline workflow (LISTERIA_HYBRID_NF)
    The INSTALL workflow has its own completion handlers in workflows/install.nf
*/

workflow.onComplete {
    // Only show main pipeline completion message if we're NOT running INSTALL
    if (workflow.commandLine.contains('-entry INSTALL')) {
        // INSTALL workflow has its own completion handlers
        return
    }

    log.info ""
    log.info "═══════════════════════════════════════════════════════════════"

    if (workflow.success) {
        log.info "Pipeline completed successfully!"
        log.info "═══════════════════════════════════════════════════════════════"
        log.info ""
        log.info "Results Summary:"
        log.info "  Output directory : ${params.outdir}"
        log.info "  Execution reports: ${params.tracedir}"
        log.info "  MultiQC report   : ${params.outdir}/multiqc/multiqc_report.html"
        log.info ""
        log.info "Assembly outputs  : ${params.outdir}/unicycler/"
        log.info "CheckM2 reports   : ${params.outdir}/checkm2/"
        log.info "QUAST reports     : ${params.outdir}/quast/"
        log.info ""
    } else {
        log.info "Pipeline failed!"
        log.info "═══════════════════════════════════════════════════════════════"
        log.info ""
        log.info "Please check the error messages above."
        log.info "Execution trace: ${params.tracedir}/execution_trace.txt"
        log.info ""
        log.info "Common issues:"
        log.info "  - Missing or incorrect input files in samplesheet"
        log.info "  - Insufficient resources (check resource configurations)"
        log.info "  - Container download failures (run: nextflow run main.nf -entry INSTALL)"
        log.info "  - Invalid parameter values"
        log.info ""
        log.info "For help, see: https://github.com/yourusername/listeria-hybrid-nf/issues"
        log.info ""
    }

    log.info "Execution summary:"
    log.info "  Duration    : ${workflow.duration}"
    log.info "  Success     : ${workflow.success}"
    log.info "  Exit status : ${workflow.exitStatus}"
    log.info "  Error report: ${workflow.errorReport ?: 'None'}"
    log.info ""
}

workflow.onError {
    // Only show main pipeline error message if we're NOT running INSTALL
    if (workflow.commandLine.contains('-entry INSTALL')) {
        // INSTALL workflow has its own error handlers
        return
    }

    log.error ""
    log.error "═══════════════════════════════════════════════════════════════"
    log.error "Pipeline execution stopped with error:"
    log.error workflow.errorMessage
    log.error "═══════════════════════════════════════════════════════════════"
    log.error ""
}

/*
========================================================================================
    WORKFLOW DESIGN NOTES (for Phase 2+ development)
========================================================================================

Design Philosophy:
- Use subworkflows ONLY where they add value (complex logic, grouping related steps)
- Use modules directly for single processes
- Keep main.nf readable and logical
- Comprehensive comments explain each step

Subworkflows vs Direct Modules:
✓ Subworkflows: INPUT_CHECK, QC_NANOPORE, ASSEMBLY_HYBRID, QC_ASSEMBLY
✓ Direct modules: FASTP, FLYE, MULTIQC

Channel Patterns:
- Standard format: tuple val(meta), path(files)
- meta contains sample information (id, single_end, etc.)
- Use .join() to combine channels by sample ID
- Use .mix() to combine different file types
- Use .collect() to gather all files for MultiQC

Error Handling:
- Validation happens before workflow starts (nf-schema)
- Processes have retry logic (see conf/base.config)
- Clear error messages in completion handlers
- Execution trace files for debugging

Resource Management:
- Process resources in conf/base.config
- Automatic retry with increased resources
- check_max() function enforces limits
- Can override per-profile or per-run

Output Organization:
results/
├── fastp/              # Illumina QC
├── porechop/           # Nanopore adapter trimming
├── filtlong/           # Nanopore quality filtering
├── flye/               # Long-read assemblies (if use_flye)
├── unicycler/          # Final hybrid assemblies
├── checkm2/            # Completeness assessment
├── quast/              # Assembly statistics
├── multiqc/            # Aggregated report
└── pipeline_info/      # Execution reports

========================================================================================
*/
