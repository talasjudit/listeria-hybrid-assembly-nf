#!/usr/bin/env nextflow
/*
========================================================================================
    CIRCULARITY_CHECK Module Unit Test
========================================================================================
    Tests the CIRCULARITY_CHECK module with both supported input formats:
      Case 1: Flye assembly_info.txt  (Flye format auto-detected by absence of circular=)
      Case 2: Unicycler FASTA         (Unicycler format auto-detected via circular= headers)

    Both cases are submitted via Channel.mix so they run in the same workflow
    invocation. The module auto-detects format from file content and names its
    output accordingly.

    Requires (both committed):
      tests/data/test_flye_info.txt
      tests/data/test_unicycler_assembly.fasta

    Usage:
      nextflow run tests/modules/circularity_check/test_circularity_check.nf \
          -c nextflow.config -profile singularity,qib
========================================================================================
*/

nextflow.enable.dsl=2

include { CIRCULARITY_CHECK                       } from '../../../modules/local/circularity_check'
include { CIRCULARITY_CHECK as CIRCULARITY_CHECK2 } from '../../../modules/local/circularity_check'
include { CIRCULARITY_CHECK as CIRCULARITY_CHECK3 } from '../../../modules/local/circularity_check'

// Verify required test data is present
def missing = ['test_flye_info.txt', 'test_unicycler_assembly.fasta', 'test_unicycler_linear_assembly.fasta'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nThese files should be committed to the repo — check tests/data/."
}

workflow {
    log.info "Testing CIRCULARITY_CHECK module (Flye + Unicycler formats)..."

    // Case 1: Flye assembly_info.txt — no circular= in content → flye_draft report
    def flye_info        = file("${launchDir}/tests/data/test_flye_info.txt",                     checkIfExists: true)
    // Case 2: Unicycler FASTA — all contigs circular=true → Status: PASSED
    def unicycler_fasta  = file("${launchDir}/tests/data/test_unicycler_assembly.fasta",          checkIfExists: true)
    // Case 3: Unicycler FASTA — large contig with no circular= field → Status: WARNING
    def unicycler_linear = file("${launchDir}/tests/data/test_unicycler_linear_assembly.fasta",   checkIfExists: true)

    CIRCULARITY_CHECK(
        Channel.value([ [id: 'test_flye'], flye_info ])
    )

    CIRCULARITY_CHECK2(
        Channel.value([ [id: 'test_unicycler'], unicycler_fasta ])
    )

    CIRCULARITY_CHECK3(
        Channel.value([ [id: 'test_unicycler_linear'], unicycler_linear ])
    )

    // Verify Case 1: Flye
    CIRCULARITY_CHECK.out.report
        .view { meta, report ->
            def content = report.text
            log.info "--- Case 1: Flye assembly_info.txt ---"
            log.info "✓ Report file: ${report.name}"
            assert report.name.endsWith("_flye_draft_circularity_mqc.tsv") : "FAIL: expected _flye_draft_circularity_mqc.tsv suffix"
            assert content.contains("sample\tsource\tcontig")          : "FAIL: missing TSV header"
            assert content.contains("flye_draft")                      : "FAIL: source column not 'flye_draft'"
            assert content.contains("# Status:")                       : "FAIL: missing Status line"
            log.info "✓ Status line present"
            log.info "✓ Flye format detected correctly"
        }

    // Verify Case 2: Unicycler all-circular → PASSED
    CIRCULARITY_CHECK2.out.report
        .view { meta, report ->
            def content = report.text
            log.info "--- Case 2: Unicycler FASTA (all circular) ---"
            assert report.name.endsWith("_unicycler_circularity_mqc.tsv")  : "FAIL: expected _unicycler_circularity_mqc.tsv suffix"
            assert content.contains("sample\tsource\tcontig")              : "FAIL: missing TSV header"
            assert content.contains("unicycler")                           : "FAIL: source column not 'unicycler'"
            assert content.contains("# Status: PASSED")                   : "FAIL: expected PASSED for all-circular assembly"
            log.info "✓ All-circular unicycler assembly → PASSED"
        }

    // Verify Case 3: Unicycler with large linear contig (no circular= field) → WARNING
    CIRCULARITY_CHECK3.out.report
        .view { meta, report ->
            def content = report.text
            log.info "--- Case 3: Unicycler FASTA (large linear contig, no circular= field) ---"
            assert report.name.endsWith("_unicycler_circularity_mqc.tsv")  : "FAIL: expected _unicycler_circularity_mqc.tsv suffix"
            assert content.contains("LINEAR")                              : "FAIL: expected LINEAR entry"
            assert content.contains("# Status: WARNING")                  : "FAIL: expected WARNING for large linear contig"
            log.info "✓ Large contig without circular= field → WARNING"
        }

    CIRCULARITY_CHECK.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "CIRCULARITY_CHECK test complete. Results in: ${params.outdir}"
}
