/*
========================================================================================
    ASSEMBLY_HYBRID Subworkflow
========================================================================================
    Hybrid genome assembly using Unicycler with optional Flye assembly input
    
    - Standard mode: Unicycler with short + long reads
    - Flye mode: Unicycler uses existing Flye assembly as scaffold

    Processes:
    - UNICYCLER: Hybrid assembly (handles both modes via optional assembly input)
========================================================================================
*/

// Import Unicycler process (handles optional Flye assembly)
include { UNICYCLER } from '../../modules/local/unicycler'

workflow ASSEMBLY_HYBRID {

    take:
    illumina_reads  // channel: tuple val(meta), path(reads) - [R1, R2]
    nanopore_reads  // channel: tuple val(meta), path(reads) - nanopore reads
    flye_assembly   // channel: tuple val(meta), path(assembly) - Flye assembly (or empty channel)

    main:
    // Combine all inputs by sample ID
    // Result: [meta, [R1, R2], nanopore, assembly_or_empty]
    ch_unicycler_input = illumina_reads
        .join(nanopore_reads, by: 0)
        .join(flye_assembly, by: 0, remainder: true)
        .map { meta, illumina, nanopore, assembly ->
            // If no Flye assembly, use empty list
            def asm = assembly ?: []
            [meta, illumina, nanopore, asm]
        }
    
    // Run Unicycler (handles both modes via optional assembly parameter)
    UNICYCLER(ch_unicycler_input)

    emit:
    assembly = UNICYCLER.out.assembly  // channel: tuple val(meta), path(assembly) - final assembly FASTA
    gfa      = UNICYCLER.out.gfa       // channel: tuple val(meta), path(gfa) - assembly graph
    logs     = UNICYCLER.out.process_log // channel: tuple val(meta), path(log) - assembly log
    versions = UNICYCLER.out.versions  // channel: path(versions.yml) - version info
}

/*
========================================================================================
    ASSEMBLY MODES EXPLANATION
========================================================================================

Mode 1: Standard Hybrid Assembly (params.use_flye = false)
----------------------------------------------------------
Process: UNICYCLER
Input:
  - Illumina paired-end reads (quality trimmed)
  - Nanopore long reads (adapter-trimmed, quality-filtered)

Workflow:
  1. Build assembly graph from Illumina reads (SPAdes)
  2. Simplify graph and resolve small repeats
  3. Use Nanopore reads to bridge contigs and resolve larger repeats
  4. Polish assembly with Illumina reads

Best for:
  - Standard bacterial genomes without complex repeat structures
  - When you want Unicycler to handle everything
  - Faster execution

Mode 2: Hybrid with Existing Flye Assembly (params.use_flye = true)
-------------------------------------------------------------------
Process: UNICYCLER_WITH_FLYE
Input:
  - Illumina paired-end reads (quality trimmed)
  - Nanopore long reads (adapter-trimmed, quality-filtered)
  - Flye long-read assembly (used as scaffold)

Workflow:
  1. Flye creates initial long-read assembly
  2. Unicycler uses Flye assembly as starting point
  3. Illumina reads used to polish and correct the assembly
  4. Results in higher accuracy than Flye alone

Best for:
  - Complex genomes with challenging repeat structures
  - When long-read assembly quality is good
  - Genomes where Unicycler alone struggles
  - When you want maximum contiguity and accuracy

Comparison:
-----------
Standard Mode:
  + Faster execution
  + Simpler workflow
  + Works well for most bacterial genomes
  - May struggle with complex repeats

With Flye Mode:
  + Better for complex genomes
  + Higher contiguity (larger contigs)
  + Better repeat resolution
  - Slower (runs both Flye and Unicycler)
  - Requires high-quality long reads

Performance:
------------
Standard Mode:
  - Runtime: 2-8 hours per sample (typical)
  - Memory: 16-32 GB
  - Result: Usually 1-50 contigs for bacterial genomes

With Flye Mode:
  - Runtime: 4-12 hours per sample (typical)
  - Memory: 32-64 GB
  - Result: Often fewer, larger contigs (sometimes complete chromosome)

========================================================================================
*/
