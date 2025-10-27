/*
========================================================================================
    ASSEMBLY_HYBRID Subworkflow
========================================================================================
    Hybrid genome assembly with conditional logic for Flye integration

    Purpose:
    - Handles complex decision between two Unicycler assembly modes
    - Standard hybrid: Unicycler with short + long reads
    - With Flye: Unicycler using existing Flye assembly as scaffold
    - Hides conditional complexity from main workflow

    Why this is a subworkflow:
    - Complex conditional logic based on params.use_flye
    - Two different processes with similar inputs/outputs
    - Centralizes assembly strategy decision
    - Keeps main.nf clean and readable

    Processes (conditionally executed):
    - UNICYCLER: Standard hybrid assembly (short + long reads)
    - UNICYCLER_WITH_FLYE: Hybrid with existing Flye assembly

    TODO: Implement conditional assembly logic in Phase 2+
========================================================================================
*/

// Import both Unicycler processes
include { UNICYCLER } from '../../modules/local/unicycler'
include { UNICYCLER_WITH_FLYE } from '../../modules/local/unicycler_with_flye'

workflow ASSEMBLY_HYBRID {

    take:
    illumina_reads  // channel: tuple val(meta), path(reads) - [R1, R2]
    nanopore_reads  // channel: tuple val(meta), path(reads) - nanopore reads
    flye_assembly   // channel: tuple val(meta), path(assembly) - Flye assembly (optional/empty)

    main:

    // TODO Phase 2: Implement conditional assembly logic
    //
    // This subworkflow decides which Unicycler mode to use based on:
    // - params.use_flye flag
    // - Presence of Flye assembly in the channel
    //
    // Example implementation:
    //
    // // Combine Illumina and Nanopore channels by sample ID
    // ch_reads_combined = illumina_reads
    //     .join(nanopore_reads, by: 0)
    //     // Result: [meta, [R1, R2], nanopore]
    //
    // // Conditional execution based on params.use_flye
    // if (params.use_flye) {
    //     // Mode 1: Hybrid assembly WITH existing Flye assembly
    //
    //     // Join reads with Flye assembly
    //     ch_with_flye = ch_reads_combined
    //         .join(flye_assembly, by: 0)
    //         // Result: [meta, [R1, R2], nanopore, flye_assembly]
    //
    //     // Run Unicycler with existing assembly
    //     UNICYCLER_WITH_FLYE(ch_with_flye)
    //
    //     // Collect outputs
    //     ch_assembly = UNICYCLER_WITH_FLYE.out.assembly
    //     ch_gfa = UNICYCLER_WITH_FLYE.out.gfa
    //     ch_log = UNICYCLER_WITH_FLYE.out.log
    //     ch_versions = UNICYCLER_WITH_FLYE.out.versions
    //
    // } else {
    //     // Mode 2: Standard hybrid assembly (no Flye)
    //
    //     // Run standard Unicycler
    //     UNICYCLER(ch_reads_combined)
    //
    //     // Collect outputs
    //     ch_assembly = UNICYCLER.out.assembly
    //     ch_gfa = UNICYCLER.out.gfa
    //     ch_log = UNICYCLER.out.log
    //     ch_versions = UNICYCLER.out.versions
    // }
    //
    // Alternative implementation using branching:
    // This approach is more DSL2-idiomatic but more complex
    //
    // ch_reads_combined
    //     .branch {
    //         with_flye: params.use_flye
    //         standard: !params.use_flye
    //     }
    //     .set { ch_branched }
    //
    // Then handle each branch separately
    //
    // Notes:
    // - The join operation matches samples by meta.id
    // - Both processes produce identical output structure
    // - Choice is made at workflow start, not per-sample
    // - All samples use the same assembly mode

    // Placeholder channels for Phase 1
    ch_assembly = Channel.empty()
    ch_gfa = Channel.empty()
    ch_log = Channel.empty()
    ch_versions = Channel.empty()

    emit:
    assembly = ch_assembly  // channel: tuple val(meta), path(assembly) - final assembly FASTA
    gfa      = ch_gfa       // channel: tuple val(meta), path(gfa) - assembly graph
    log      = ch_log       // channel: tuple val(meta), path(log) - assembly log
    versions = ch_versions  // channel: path(versions.yml) - version info
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
