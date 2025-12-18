#!/usr/bin/env nextflow
/*
========================================================================================
    Hybrid Bacterial Genome Assembly Pipeline - Main Workflow
========================================================================================
    Github: https://github.com/talasjudit/listeria-hybrid-assembly-nf
    
    Pipeline Steps:
    1. Parse samplesheet and validate inputs
    2. QC Illumina reads (FastP)
    3. QC Nanopore reads (Porechop + Filtlong)
    4. Optional: Flye long-read assembly
    5. Hybrid assembly (Unicycler with optional Flye input)
    6. Assembly QC (CheckM2 + QUAST)
    7. Aggregate QC report (MultiQC)
========================================================================================
*/

nextflow.enable.dsl=2

/*
========================================================================================
    IMPORT SUBWORKFLOWS
========================================================================================
*/

include { INPUT_CHECK     } from '../subworkflows/local/input_check'
include { QC_NANOPORE     } from '../subworkflows/local/qc_nanopore'
include { ASSEMBLY_HYBRID } from '../subworkflows/local/assembly_hybrid'
include { QC_ASSEMBLY     } from '../subworkflows/local/qc_assembly'

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { FASTP           } from '../modules/local/fastp'
include { FLYE            } from '../modules/local/flye'
include { MULTIQC         } from '../modules/local/multiqc'
include { COVERAGE_CHECK  } from '../modules/local/coverage_check'

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
    
    //
    // PRINT PIPELINE INFO
    //
    log.info """
    ==============================================
     Hybrid Bacterial Assembly Pipeline
    ==============================================
    Input samplesheet : ${params.input}
    Output directory  : ${params.outdir}
    Assembly strategy : ${params.use_flye ? 'Flye + Unicycler' : 'Unicycler only'}
    Genome size       : ${params.genome_size}
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
    // SUBWORKFLOW: Quality control of Nanopore reads (Porechop + Filtlong)
    //
    QC_NANOPORE(ch_nanopore)
    
    ch_nanopore_filtered = QC_NANOPORE.out.reads  // channel: [meta, filtered.fastq.gz]
    
    //
    // MODULE: Coverage check (validation gate)
    // Combines QC'd reads and checks if coverage meets thresholds
    //
    ch_coverage_input = ch_illumina_trimmed
        .join(ch_nanopore_filtered, by: 0)
        .map { meta, illumina, nanopore -> [meta, illumina, nanopore] }
    
    COVERAGE_CHECK(ch_coverage_input)
    
    // Branch samples into passed and failed based on coverage report
    ch_coverage_branched = COVERAGE_CHECK.out.results
        .branch { meta, illumina, nanopore, report ->
            passed: report.text.contains("Status: PASSED")
            failed: report.text.contains("Status: FAILED")
        }
    
    // Log failed samples
    ch_coverage_branched.failed
        .subscribe { meta, illumina, nanopore, report ->
            log.warn "Sample ${meta.id} FAILED coverage check - see ${report.name} for details"
        }
    
    // Extract passing samples for assembly (drop the report from tuple)
    ch_illumina_passed = ch_coverage_branched.passed
        .map { meta, illumina, nanopore, report -> [meta, illumina] }
    
    ch_nanopore_passed = ch_coverage_branched.passed
        .map { meta, illumina, nanopore, report -> [meta, nanopore] }
    
    //
    // CONDITIONAL: Flye long-read assembly (if params.use_flye = true)
    //
    if (params.use_flye) {
        log.info "Running Flye assembly before Unicycler..."
        FLYE(ch_nanopore_passed)
        ch_flye_assembly = FLYE.out.assembly  // channel: [meta, assembly.fasta]
    } else {
        log.info "Skipping Flye - running standard Unicycler hybrid assembly"
        ch_flye_assembly = Channel.empty()
    }
    
    //
    // SUBWORKFLOW: Hybrid assembly (with or without Flye)
    // Only processes samples that passed coverage check
    //
    ASSEMBLY_HYBRID(
        ch_illumina_passed,
        ch_nanopore_passed,
        ch_flye_assembly
    )
    
    ch_assembly = ASSEMBLY_HYBRID.out.assembly  // channel: [meta, assembly.fasta]
    
    //
    // SUBWORKFLOW: Assembly quality assessment (CheckM2 + QUAST)
    //
    QC_ASSEMBLY(ch_assembly)
    
    //
    // MODULE: Aggregate QC reports with MultiQC
    //
    
    // Collect all QC outputs for MultiQC
    // Extract files from [meta, file] tuples and flatten nested channels
    ch_multiqc_files = Channel.empty()
        .mix(FASTP.out.json.map { meta, json -> json })
        .mix(FASTP.out.html.map { meta, html -> html })
        .mix(QC_NANOPORE.out.logs.map { meta, log -> log }.flatten())
        .mix(COVERAGE_CHECK.out.results.map { meta, illumina, nanopore, report -> report })
        .mix(ASSEMBLY_HYBRID.out.logs.map { meta, log -> log })
        .mix(QC_ASSEMBLY.out.logs.map { meta, log -> log }.flatten())
        .mix(QC_ASSEMBLY.out.checkm2_reports.map { meta, report -> report })
        .mix(QC_ASSEMBLY.out.quast_dir.map { meta, dir -> dir })
        .collect()
    
    // MultiQC config file (optional - will use defaults if not found)
    ch_multiqc_config = file("${projectDir}/assets/multiqc_config.yaml", checkIfExists: false)
    
    // Run MultiQC
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
