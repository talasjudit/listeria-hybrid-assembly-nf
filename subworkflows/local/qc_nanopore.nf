/*
========================================================================================
    QC_NANOPORE Subworkflow
========================================================================================
    Quality control for Nanopore reads: adapter trimming + quality filtering

    Purpose:
    - Groups two processes that always run together in sequence
    - Adapter removal with Porechop ABI
    - Quality filtering with Filtlong
    - Collects logs and versions from both steps

    Why this is a subworkflow:
    - These two processes are always executed together
    - Simplifies main workflow by grouping related operations
    - Makes the pipeline structure clearer

    Processes:
    1. PORECHOP_ABI - Removes adapters from Nanopore reads
    2. FILTLONG - Filters reads by quality and length

    TODO: Implement subworkflow logic in Phase 2+
========================================================================================
*/

// Import required processes
include { PORECHOP_ABI } from '../../modules/local/porechop_abi'
include { FILTLONG } from '../../modules/local/filtlong'

workflow QC_NANOPORE {

    take:
    reads  // channel: tuple val(meta), path(reads) - raw Nanopore reads

    main:

    // TODO Phase 2: Implement QC pipeline for Nanopore reads
    //
    // This subworkflow chains two processes:
    // 1. Adapter trimming with Porechop ABI
    // 2. Quality filtering with Filtlong
    //
    // Example implementation:
    //
    // // Step 1: Remove adapters
    // PORECHOP_ABI(reads)
    //
    // // Step 2: Filter by quality and length
    // FILTLONG(PORECHOP_ABI.out.reads)
    //
    // // Collect all logs for MultiQC
    // ch_logs = PORECHOP_ABI.out.log
    //     .mix(FILTLONG.out.log)
    //
    // // Collect all versions
    // ch_versions = PORECHOP_ABI.out.versions
    //     .mix(FILTLONG.out.versions)
    //
    // Data flow:
    //   Input: Raw Nanopore reads
    //   → PORECHOP_ABI: Remove adapters
    //   → FILTLONG: Filter by quality/length
    //   Output: High-quality, adapter-free Nanopore reads
    //
    // Notes:
    // - Processes run sequentially (Filtlong needs Porechop output)
    // - Both logs should be collected for QC reporting
    // - Filter parameters from params.min_read_length and params.filtlong_keep_percent

    // Placeholder channels for Phase 1
    ch_reads = Channel.empty()
    ch_logs = Channel.empty()
    ch_versions = Channel.empty()

    emit:
    reads    = ch_reads     // channel: tuple val(meta), path(reads) - QC'd Nanopore reads
    logs     = ch_logs      // channel: path(log) - all log files
    versions = ch_versions  // channel: path(versions.yml) - all version files
}

/*
========================================================================================
    EXPECTED BEHAVIOR
========================================================================================

Input:
- Nanopore reads in FASTQ format (gzipped)
- Raw reads directly from sequencer or basecaller

Processing Steps:
1. Adapter Removal (Porechop ABI):
   - Detects and removes sequencing adapters
   - Removes chimeric reads (reads with middle adapters)
   - Uses ab initio detection for robust adapter finding

2. Quality Filtering (Filtlong):
   - Filters reads below minimum length threshold (default: 6000 bp)
   - Keeps top N% of reads by quality (default: 95%)
   - Removes low-quality reads that would hurt assembly

Output:
- High-quality, adapter-free Nanopore reads ready for assembly
- Log files documenting filtering statistics
- Version information for reproducibility

Typical Results:
- Input: 100,000 reads, 1.5 Gb total
- After Porechop: ~98,000 reads (removes adapters, chimeras)
- After Filtlong: ~93,000 reads (keeps top 95%)
- Final output: High-quality reads suitable for hybrid assembly

========================================================================================
*/
