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

include { FASTP   } from '../modules/local/fastp'
include { FLYE    } from '../modules/local/flye'
include { MULTIQC } from '../modules/local/multiqc'

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
    // CONDITIONAL: Flye long-read assembly (if params.use_flye = true)
    //
    if (params.use_flye) {
        log.info "Running Flye assembly before Unicycler..."
        FLYE(ch_nanopore_filtered)
        ch_flye_assembly = FLYE.out.assembly  // channel: [meta, assembly.fasta]
    } else {
        log.info "Skipping Flye - running standard Unicycler hybrid assembly"
        ch_flye_assembly = Channel.empty()
    }
    
    //
    // SUBWORKFLOW: Hybrid assembly (with or without Flye)
    //
    ASSEMBLY_HYBRID(
        ch_illumina_trimmed,
        ch_nanopore_filtered,
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
