/*
========================================================================================
    QC_ASSEMBLY Subworkflow
========================================================================================
    Assembly quality assessment using CheckM2 and QUAST

    Purpose:
    - Groups two processes that always run together
    - CheckM2 assesses completeness and contamination
    - QUAST provides assembly statistics (N50, contig counts, etc.)
    - Both processes run in parallel on the same assembly

    Why this is a subworkflow:
    - These two processes always run together
    - Both analyze the same input (assembly)
    - Simplifies main workflow
    - Collects all assembly QC metrics in one place

    Processes (run in parallel):
    1. CHECKM2 - Completeness and contamination assessment
    2. QUAST - Assembly statistics and quality metrics

    TODO: Implement subworkflow logic in Phase 2+
========================================================================================
*/

// Import required processes
include { CHECKM2 } from '../../modules/local/checkm2'
include { QUAST } from '../../modules/local/quast'

workflow QC_ASSEMBLY {

    take:
    assemblies  // channel: tuple val(meta), path(assembly) - genome assemblies

    main:

    // TODO Phase 2: Implement assembly QC
    //
    // This subworkflow runs two QC processes in parallel:
    // 1. CheckM2: Assesses genome completeness and contamination
    // 2. QUAST: Calculates assembly statistics
    //
    // Example implementation:
    //
    // // Run CheckM2 for completeness assessment
    // CHECKM2(assemblies)
    //
    // // Run QUAST for assembly statistics (runs in parallel with CheckM2)
    // QUAST(assemblies)
    //
    // // Collect all reports for MultiQC
    // ch_checkm2_reports = CHECKM2.out.report
    // ch_quast_reports = QUAST.out.report
    //
    // // Collect logs
    // ch_logs = CHECKM2.out.log
    //     .mix(QUAST.out.log)
    //
    // // Collect versions
    // ch_versions = CHECKM2.out.versions
    //     .mix(QUAST.out.versions)
    //
    // Data flow:
    //   Input: Assembly FASTA file
    //   ├─→ CHECKM2: Completeness/contamination analysis
    //   └─→ QUAST: Assembly statistics
    //   Output: QC reports from both tools
    //
    // Notes:
    // - Both processes run in parallel (independent)
    // - Both take the same input (assembly file)
    // - Reports should be collected for MultiQC
    // - CheckM2 requires significant memory (check base.config)

    // Placeholder channels for Phase 1
    ch_checkm2_reports = Channel.empty()
    ch_quast_reports = Channel.empty()
    ch_logs = Channel.empty()
    ch_versions = Channel.empty()

    emit:
    checkm2_reports = ch_checkm2_reports  // channel: tuple val(meta), path(report) - CheckM2 TSV reports
    quast_reports   = ch_quast_reports    // channel: tuple val(meta), path(report) - QUAST TSV reports
    logs            = ch_logs             // channel: tuple val(meta), path(log) - all log files
    versions        = ch_versions         // channel: path(versions.yml) - version files
}

/*
========================================================================================
    ASSEMBLY QC METRICS EXPLANATION
========================================================================================

CheckM2 Metrics (Completeness & Contamination)
----------------------------------------------
Purpose: Assess how complete and pure the genome assembly is

Key Metrics:
1. Completeness (%)
   - Percentage of expected genes present in the assembly
   - Based on conserved marker genes
   - Target: >95% for high-quality genome
   - Warning: <90%
   - Poor: <80%

2. Contamination (%)
   - Percentage of unexpected/foreign DNA
   - Detected by duplicate marker genes
   - Target: <2% for clean assembly
   - Warning: >5%
   - Poor: >10%

3. Completeness - 5*Contamination (Combined Quality Score)
   - Simple quality metric combining both factors
   - Target: >90 for publication-quality genome
   - Accounts for trade-off between completeness and contamination

Example Results:
  Excellent: 99% complete, 0.5% contamination
  Good:      97% complete, 2% contamination
  Warning:   89% complete, 3% contamination
  Poor:      75% complete, 8% contamination

QUAST Metrics (Assembly Statistics)
-----------------------------------
Purpose: Assess structural quality and contiguity of assembly

Key Metrics:
1. Number of Contigs
   - Fewer is better for bacterial genomes
   - Target: <50 contigs for good assembly
   - Excellent: 1-10 contigs (complete or near-complete)
   - Poor: >200 contigs (fragmented)

2. Total Length (bp)
   - Should match expected genome size
   - Bacterial genomes typically: 2-6 Mb
   - Listeria: ~2.9-3.0 Mb expected

3. N50 (bp)
   - Half the assembly is in contigs of this size or larger
   - Larger is better
   - Target: >100 Kb for bacterial hybrid assembly
   - Excellent: >500 Kb or complete chromosome
   - Poor: <10 Kb (very fragmented)

4. L50
   - Number of contigs containing 50% of assembly
   - Smaller is better
   - Target: <10 for good assembly
   - Excellent: 1-3
   - Poor: >50

5. Largest Contig (bp)
   - Size of the biggest contig
   - Should approach genome size for good assembly
   - Excellent: >2 Mb (chromosome-sized)
   - Good: >100 Kb
   - Poor: <50 Kb

6. GC Content (%)
   - Should match expected for the organism
   - Listeria: ~38% expected
   - Useful for detecting contamination
   - Large deviations indicate problems

Example Results for Good Bacterial Hybrid Assembly:
  Contigs: 15
  Total length: 2,950,000 bp
  N50: 450,000 bp
  L50: 3
  Largest contig: 2,100,000 bp
  GC: 37.8%

Combined Interpretation:
-----------------------
Excellent Assembly:
  - CheckM2: >97% complete, <2% contamination
  - QUAST: <20 contigs, N50 >200 Kb

Good Assembly:
  - CheckM2: >90% complete, <5% contamination
  - QUAST: <50 contigs, N50 >50 Kb

Problematic Assembly:
  - CheckM2: <80% complete or >10% contamination
  - QUAST: >200 contigs, N50 <10 Kb
  - Action: Review input data quality, adjust parameters, or increase coverage

Common Issues and Solutions:
---------------------------
1. Low completeness (<90%):
   - Check sequencing coverage (need 30-50x Illumina, 50x+ Nanopore)
   - Review read quality metrics
   - May indicate poor DNA quality

2. High contamination (>5%):
   - Sample may have mixed species
   - DNA extraction may have contamination
   - Check FastP/QC reports for issues

3. High fragmentation (many small contigs):
   - Insufficient Nanopore coverage
   - Poor Nanopore read quality
   - Try adjusting Filtlong parameters
   - Consider using Flye mode (params.use_flye = true)

4. Mismatched genome size:
   - Much larger: likely contamination or plasmids
   - Much smaller: incomplete coverage or failed assembly

========================================================================================
*/
