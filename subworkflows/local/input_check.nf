/*
========================================================================================
    INPUT_CHECK Subworkflow
========================================================================================
    Parse and validate samplesheet using nf-schema plugin

    Purpose:
    - Parse samplesheet CSV file
    - Validate format and file existence (handled by nf-schema)
    - Create separate channels for Illumina and Nanopore reads
    - Add metadata to samples

    Why this is a subworkflow:
    - Complex parsing and channel manipulation logic
    - Reusable across different entry points
    - Centralizes input validation

    Dependencies:
    - nf-schema plugin
    - assets/schema_input.json (validation schema)

    TODO: Implement samplesheet parsing in Phase 2+
========================================================================================
*/

// Import nf-schema plugin functions
include { fromSamplesheet } from 'plugin/nf-schema'

workflow INPUT_CHECK {

    take:
    samplesheet  // path: Path to CSV samplesheet file

    main:

    // TODO Phase 2: Implement samplesheet parsing
    //
    // The nf-schema plugin will:
    // 1. Parse the CSV file
    // 2. Validate against assets/schema_input.json
    // 3. Check that all files exist
    // 4. Ensure sample names are unique
    // 5. Create a channel with the data
    //
    // Example implementation:
    //
    // // Parse samplesheet using nf-schema
    // ch_input = Channel.fromSamplesheet('input')
    //     .map { meta, nanopore, illumina_1, illumina_2 ->
    //         // Create new metadata map
    //         def new_meta = [
    //             id: meta.sample,
    //             single_end: false  // Paired-end Illumina data
    //         ]
    //
    //         // Return tuple with metadata and file paths
    //         // Format: [meta, [illumina_R1, illumina_R2], nanopore]
    //         return [new_meta, [file(illumina_1), file(illumina_2)], file(nanopore)]
    //     }
    //
    // // Split into separate channels for different read types
    // ch_illumina = ch_input
    //     .map { meta, illumina, nanopore ->
    //         // Return: [meta, [R1, R2]]
    //         [meta, illumina]
    //     }
    //
    // ch_nanopore = ch_input
    //     .map { meta, illumina, nanopore ->
    //         // Return: [meta, nanopore]
    //         [meta, nanopore]
    //     }
    //
    // Notes:
    // - The 'input' parameter name must match the parameter in nextflow.config
    // - File existence is validated automatically by the schema
    // - Sample names are validated for uniqueness
    // - All validation errors will stop the pipeline with clear messages

    // Placeholder channels for Phase 1
    ch_illumina = Channel.empty()
    ch_nanopore = Channel.empty()

    emit:
    illumina = ch_illumina  // channel: tuple val(meta), path(reads) where reads = [R1, R2]
    nanopore = ch_nanopore  // channel: tuple val(meta), path(reads) where reads = nanopore.fq.gz
}

/*
========================================================================================
    EXPECTED SAMPLESHEET FORMAT
========================================================================================

CSV format (with header):
sample,nanopore,illumina_1,illumina_2
Sample_001,/path/to/nano1.fastq.gz,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
Sample_002,/path/to/nano2.fastq.gz,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz

Requirements (enforced by assets/schema_input.json):
- Header row must be present
- All columns are required
- Sample names must be unique and cannot contain spaces
- All file paths must be absolute paths
- All files must exist and be readable
- Files must have .fq.gz or .fastq.gz extension

========================================================================================
*/
