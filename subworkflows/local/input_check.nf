/*
========================================================================================
    INPUT_CHECK Subworkflow
========================================================================================
    Parse and validate samplesheet using nf-schema plugin.
    Creates separate channels for Illumina and Nanopore reads with metadata.

    Dependencies: nf-schema plugin (v2.0+), assets/schema_input.json
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
