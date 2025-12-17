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

    Dependencies:
    - nf-schema plugin (v2.0+)
    - assets/schema_input.json (validation schema)
========================================================================================
*/

// Import nf-schema plugin function
include { samplesheetToList } from 'plugin/nf-schema'

workflow INPUT_CHECK {

    take:
    samplesheet  // path: Path to CSV samplesheet file

    main:
    // Parse samplesheet using nf-schema 2.0 syntax
    // samplesheetToList returns a Groovy list, convert to channel with Channel.fromList()
    ch_input = Channel.fromList(samplesheetToList(params.input, "${launchDir}/assets/schema_input.json"))
        .map { row ->
            def meta = [id: row[0], single_end: false]
            // Schema order: sample, nanopore, illumina_1, illumina_2
            // row[0] = sample
            // row[1] = nanopore
            // row[2] = illumina_1
            // row[3] = illumina_2
            [meta, [file(row[2]), file(row[3])], file(row[1])]
        }

    // Split into separate channels for different read types
    ch_illumina = ch_input
        .map { meta, illumina, nanopore ->
            [meta, illumina]
        }

    ch_nanopore = ch_input
        .map { meta, illumina, nanopore ->
            [meta, nanopore]
        }

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
