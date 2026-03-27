#!/usr/bin/env nextflow
/*
========================================================================================
    Hybrid Bacterial Genome Assembly Pipeline - Main Workflow
========================================================================================
    Github: https://github.com/talasjudit/listeria-hybrid-assembly-nf

    Pipeline Steps:
    1. Parse samplesheet and validate inputs
    2. QC Illumina reads (FastP)
    3. QC Nanopore reads (Porechop ABI + Filtlong)
    4. Coverage check gate (SeqKit)
    5. [flye_unicycler / flye_polypolish modes] Flye long-read assembly
    6. Mode-specific assembly:
         unicycler      → ASSEMBLY_UNICYCLER (Unicycler hybrid)
         flye_unicycler → ASSEMBLY_FLYE_UNICYCLER (Unicycler with Flye scaffold)
         flye_polypolish→ ASSEMBLY_POLYPOLISH (Polypolish on Flye assembly)
    7. Circularity check (before dnaapler reorientation):
         unicycler      → check Unicycler FASTA headers
         flye_unicycler → check Flye draft info + Unicycler output headers
         flye_polypolish→ check Flye draft info
    8. dnaapler chromosome reorientation (all modes)
    9. [flye_polypolish + --reference] dnadiff reference comparison
    10. Assembly QC (CheckM2 + QUAST)
    11. Aggregate QC report (MultiQC)
========================================================================================
*/

nextflow.enable.dsl=2

/*
========================================================================================
    IMPORT SUBWORKFLOWS
========================================================================================
*/

include { INPUT_CHECK           } from '../subworkflows/local/input_check'
include { QC_NANOPORE           } from '../subworkflows/local/qc_nanopore'
include { ASSEMBLY_UNICYCLER    } from '../subworkflows/local/assembly_unicycler'
include { ASSEMBLY_FLYE_UNICYCLER } from '../subworkflows/local/assembly_flye_unicycler'
include { ASSEMBLY_POLYPOLISH   } from '../subworkflows/local/assembly_polypolish'
include { QC_ASSEMBLY           } from '../subworkflows/local/qc_assembly'

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { FASTP             } from '../modules/local/fastp'
include { FLYE              } from '../modules/local/flye'
include { CIRCULARITY_CHECK } from '../modules/local/circularity_check'
include { DNAAPLER                            } from '../modules/local/dnaapler'
include { DNADIFF as DNADIFF_DRAFT            } from '../modules/local/dnadiff'
include { DNADIFF as DNADIFF_POLISHED         } from '../modules/local/dnadiff'
include { POLISHING_SUMMARY                   } from '../modules/local/polishing_summary'
include { MULTIQC                             } from '../modules/local/multiqc'
include { COVERAGE_CHECK    } from '../modules/local/coverage_check'

/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow HYBRID_ASSEMBLY {

    //
    // VALIDATE INPUTS
    //
    if (!params.input) {
        error "ERROR: Missing required parameter --input\nPlease provide a samplesheet with: --input <path/to/samplesheet.csv>"
    }

    def valid_modes = ['unicycler', 'flye_unicycler', 'flye_polypolish']
    if (!valid_modes.contains(params.assembly_mode)) {
        error "ERROR: Invalid --assembly_mode '${params.assembly_mode}'\nValid options: ${valid_modes.join(', ')}"
    }

    //
    // PRINT PIPELINE INFO
    //
    log.info """
    ==============================================
     Hybrid Bacterial Assembly Pipeline
    ==============================================
    Input samplesheet : ${params.input}
    Output directory  : ${params.outdir}
    Assembly mode     : ${params.assembly_mode}
    Genome size       : ${params.genome_size}
    Reference         : ${params.reference ?: 'not provided'}
    ==============================================
    """.stripIndent()

    //
    // SUBWORKFLOW: Parse samplesheet and validate inputs
    //
    INPUT_CHECK(params.input)

    ch_illumina = INPUT_CHECK.out.illumina  // channel: [meta, [R1, R2]]
    ch_nanopore = INPUT_CHECK.out.nanopore  // channel: [meta, reads]

    //
    // MODULE: Quality control and trimming of Illumina reads
    //
    FASTP(ch_illumina)

    ch_illumina_trimmed = FASTP.out.reads  // channel: [meta, [R1_trim, R2_trim]]

    //
    // SUBWORKFLOW: Quality control of Nanopore reads (Porechop ABI + Filtlong)
    //
    QC_NANOPORE(ch_nanopore)

    ch_nanopore_filtered = QC_NANOPORE.out.reads  // channel: [meta, filtered.fastq.gz]

    //
    // MODULE: Coverage check gate
    //
    ch_coverage_input = ch_illumina_trimmed
        .join(ch_nanopore_filtered, by: 0)
        .map { meta, illumina, nanopore -> [meta, illumina, nanopore] }

    COVERAGE_CHECK(ch_coverage_input)

    ch_coverage_branched = COVERAGE_CHECK.out.results
        .branch { meta, illumina, nanopore, report ->
            passed: report.text.contains("Status: PASSED")
            failed: report.text.contains("Status: FAILED")
        }

    ch_coverage_branched.failed
        .subscribe { meta, illumina, nanopore, report ->
            log.warn "Sample ${meta.id} FAILED coverage check - see ${report.name} for details"
        }

    ch_illumina_passed = ch_coverage_branched.passed
        .map { meta, illumina, nanopore, report -> [meta, illumina] }

    ch_nanopore_passed = ch_coverage_branched.passed
        .map { meta, illumina, nanopore, report -> [meta, nanopore] }

    //
    // MODULE: Flye long-read assembly (flye_unicycler and flye_polypolish modes only)
    //
    if (params.assembly_mode in ['flye_unicycler', 'flye_polypolish']) {
        FLYE(ch_nanopore_passed)
        ch_flye_assembly = FLYE.out.assembly    // channel: [meta, *_flye.fasta]
        ch_flye_info     = FLYE.out.info        // channel: [meta, *_flye_info.txt]
        ch_flye_logs     = FLYE.out.process_log
    } else {
        ch_flye_assembly = Channel.empty()
        ch_flye_info     = Channel.empty()
        ch_flye_logs     = Channel.empty()
    }

    //
    // ASSEMBLY: Mode-specific subworkflow
    //
    if (params.assembly_mode == 'unicycler') {
        ASSEMBLY_UNICYCLER(ch_illumina_passed, ch_nanopore_passed)
        ch_raw_assembly  = ASSEMBLY_UNICYCLER.out.assembly
        ch_assembly_logs = ASSEMBLY_UNICYCLER.out.logs

    } else if (params.assembly_mode == 'flye_unicycler') {
        ASSEMBLY_FLYE_UNICYCLER(ch_illumina_passed, ch_nanopore_passed, ch_flye_assembly)
        ch_raw_assembly  = ASSEMBLY_FLYE_UNICYCLER.out.assembly
        ch_assembly_logs = ASSEMBLY_FLYE_UNICYCLER.out.logs

    } else if (params.assembly_mode == 'flye_polypolish') {
        ASSEMBLY_POLYPOLISH(ch_illumina_passed, ch_flye_assembly)
        ch_raw_assembly  = ASSEMBLY_POLYPOLISH.out.assembly
        ch_assembly_logs = ASSEMBLY_POLYPOLISH.out.logs
    }

    //
    // MODULE: Circularity check (runs on pre-dnaapler assembly; source varies by mode)
    //   unicycler       -> Unicycler FASTA headers (circular=true/false)
    //   flye_unicycler  -> Flye draft info + Unicycler output headers (two reports/sample)
    //   flye_polypolish -> Flye draft info only
    //
    if (params.assembly_mode == 'unicycler') {
        ch_circ_input = ch_raw_assembly
    } else if (params.assembly_mode == 'flye_unicycler') {
        ch_circ_input = ch_flye_info.mix(ch_raw_assembly)
    } else {
        ch_circ_input = ch_flye_info
    }

    CIRCULARITY_CHECK(ch_circ_input)

    CIRCULARITY_CHECK.out.report
        .subscribe { meta, report ->
            if (report.text.contains("Status: WARNING")) {
                log.warn "Sample ${meta.id}: non-circular contig(s) detected - see ${params.outdir}/qc/circularity/"
            }
        }

    //
    // MODULE: Reorient assemblies to dnaA with dnaapler (all modes)
    //
    DNAAPLER(ch_raw_assembly)

    ch_assembly = DNAAPLER.out.assembly  // channel: [meta, *_dnaapler.fasta] - final assembly

    //
    // MODULE: dnadiff reference comparison (flye_polypolish + --reference only)
    //
    if (params.assembly_mode == 'flye_polypolish' && params.reference) {
        ch_reference = Channel.value(file(params.reference, checkIfExists: true))

        // Run dnadiff on both Flye draft and Polypolish output vs the same reference
        // ext.prefix (set in base.config) gives each a distinct output filename
        DNADIFF_DRAFT   (ch_flye_assembly, ch_reference)
        DNADIFF_POLISHED(ch_raw_assembly,  ch_reference)

        // Join reports by sample and produce before/after polishing comparison
        POLISHING_SUMMARY(
            DNADIFF_DRAFT.out.report
                .join(DNADIFF_POLISHED.out.report, by: 0)
        )

        ch_dnadiff_reports   = DNADIFF_DRAFT.out.report.mix(DNADIFF_POLISHED.out.report)
        ch_dnadiff_mqc       = DNADIFF_DRAFT.out.mqc.mix(DNADIFF_POLISHED.out.mqc)
        ch_polishing_summary = POLISHING_SUMMARY.out.summary
    } else {
        if (params.assembly_mode == 'flye_polypolish' && !params.reference) {
            log.warn "Assembly mode 'flye_polypolish' - no --reference provided, skipping dnadiff"
        }
        ch_dnadiff_reports   = Channel.empty()
        ch_dnadiff_mqc       = Channel.empty()
        ch_polishing_summary = Channel.empty()
    }

    //
    // SUBWORKFLOW: Assembly quality assessment (CheckM2 + QUAST)
    // Runs on the final dnaapler-reoriented assembly
    //
    QC_ASSEMBLY(ch_assembly)

    //
    // MODULE: Aggregate QC reports with MultiQC
    //
    ch_multiqc_files = Channel.empty()
        .mix(FASTP.out.json.map { meta, json -> json })
        .mix(FASTP.out.html.map { meta, html -> html })
        .mix(QC_NANOPORE.out.logs.map { meta, log -> log }.flatten())
        .mix(COVERAGE_CHECK.out.results.map { meta, illumina, nanopore, report -> report })
        .mix(ch_flye_logs.map { meta, log -> log })
        .mix(ch_assembly_logs.map { meta, log -> log })
        .mix(DNAAPLER.out.process_log.map { meta, log -> log })
        .mix(CIRCULARITY_CHECK.out.report.map { meta, report -> report })
        .mix(ch_polishing_summary.map { meta, tsv -> tsv })
        .mix(QC_ASSEMBLY.out.logs.map { meta, log -> log }.flatten())
        .mix(QC_ASSEMBLY.out.checkm2_reports.map { meta, report -> report })
        .mix(QC_ASSEMBLY.out.quast_dir.map { meta, dir -> dir })
        .collect()

    ch_multiqc_config = file("${projectDir}/assets/multiqc_config.yaml", checkIfExists: false)

    MULTIQC(
        ch_multiqc_files,
        ch_multiqc_config
    )
}

/*
========================================================================================
    COMPLETION HANDLER
========================================================================================
*/

workflow.onComplete {
    log.info """
    ==============================================
     Pipeline Execution Complete
    ==============================================
    Status      : ${workflow.success ? '✓ SUCCESS' : '✗ FAILED'}
    Work dir    : ${workflow.workDir}
    Results     : ${params.outdir}
    Duration    : ${workflow.duration}
    Exit status : ${workflow.exitStatus}
    ==============================================
    """.stripIndent()

    if (!workflow.success) {
        log.error "Pipeline failed. Check .nextflow.log for details."
    }
}

workflow.onError {
    log.error """
    ==============================================
     Pipeline Error
    ==============================================
    Error message: ${workflow.errorMessage}
    Error report : ${workflow.errorReport}
    ==============================================
    """.stripIndent()
}
