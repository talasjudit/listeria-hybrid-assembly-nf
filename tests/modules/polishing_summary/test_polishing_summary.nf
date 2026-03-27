#!/usr/bin/env nextflow
/*
========================================================================================
    POLISHING_SUMMARY Module Unit Test
========================================================================================
    Tests the POLISHING_SUMMARY module with three cases covering all status outcomes:

      Case 1 (IMPROVED)   — draft worse than polished (SNPs+indels: 640 → 180)
      Case 2 (UNCHANGED)  — identical reports → no change in variant counts
      Case 3 (WORSE)      — polished worse than draft (reports swapped)

    Cases 1 and 2 use committed minimal dnadiff report files.
    Case 3 re-uses the same files in swapped order.

    Requires (both committed):
      tests/data/test_flye_draft.report     — draft:    AvgIdentity=99.654, SNPs=542, Indels=98
      tests/data/test_polypolish.report     — polished: AvgIdentity=99.823, SNPs=142, Indels=38

    Usage:
      nextflow run tests/modules/polishing_summary/test_polishing_summary.nf \
          -c nextflow.config -profile singularity,qib
========================================================================================
*/

nextflow.enable.dsl=2

include { POLISHING_SUMMARY                         } from '../../../modules/local/polishing_summary'
include { POLISHING_SUMMARY as POLISHING_SUMMARY2   } from '../../../modules/local/polishing_summary'
include { POLISHING_SUMMARY as POLISHING_SUMMARY3   } from '../../../modules/local/polishing_summary'

// Verify required test data is present
def missing = ['test_flye_draft.report', 'test_polypolish.report'].findAll {
    !file("${launchDir}/tests/data/${it}").exists()
}
if (missing) {
    error "Missing test data: ${missing.join(', ')}\nThese files should be committed to the repo — check tests/data/."
}

workflow {
    log.info "Testing POLISHING_SUMMARY module (IMPROVED / UNCHANGED / WORSE)..."

    def draft_report    = file("${launchDir}/tests/data/test_flye_draft.report",  checkIfExists: true)
    def polish_report   = file("${launchDir}/tests/data/test_polypolish.report",  checkIfExists: true)

    // Case 1: IMPROVED — draft (640 total) → polished (180 total)
    POLISHING_SUMMARY(
        Channel.value([ [id: 'test_improved'], draft_report, polish_report ])
    )

    // Case 2: UNCHANGED — same report used for both → variant count delta = 0
    POLISHING_SUMMARY2(
        Channel.value([ [id: 'test_unchanged'], draft_report, draft_report ])
    )

    // Case 3: WORSE — reports swapped so "polished" has more variants than "draft"
    POLISHING_SUMMARY3(
        Channel.value([ [id: 'test_worse'], polish_report, draft_report ])
    )

    // Verify Case 1: IMPROVED
    POLISHING_SUMMARY.out.summary
        .view { meta, tsv ->
            def content = tsv.text
            log.info "--- Case 1: IMPROVED ---"
            log.info "✓ Report file: ${tsv.name}"
            assert tsv.name.endsWith("_polishing_summary_mqc.tsv")                              : "FAIL: expected _polishing_summary.tsv suffix"
            assert content.contains("# id: 'polishing_summary'")                            : "FAIL: missing MultiQC id header"
            assert content.contains("# section_name: 'Polishing Summary'")                 : "FAIL: missing section_name header"
            assert content.contains("# plot_type: 'table'")                                 : "FAIL: missing plot_type header"
            assert content.contains("Sample\tAvg Identity (draft)\tAvg Identity (polished)") : "FAIL: missing TSV column header"
            assert content.contains("IMPROVED")                                              : "FAIL: expected IMPROVED status"
            assert content.contains("# Status: IMPROVED")                                   : "FAIL: missing # Status: IMPROVED comment"
            assert content.contains("99.654")                                                : "FAIL: draft AvgIdentity not found"
            assert content.contains("99.823")                                                : "FAIL: polished AvgIdentity not found"
            log.info "✓ Status: IMPROVED (correct)"
            log.info "✓ MultiQC headers present"
            log.info "✓ Identity values present"
        }

    // Verify Case 2: UNCHANGED
    POLISHING_SUMMARY2.out.summary
        .view { meta, tsv ->
            def content = tsv.text
            log.info "--- Case 2: UNCHANGED ---"
            assert tsv.name.endsWith("_polishing_summary_mqc.tsv") : "FAIL: expected _polishing_summary.tsv suffix"
            assert content.contains("UNCHANGED")               : "FAIL: expected UNCHANGED status"
            assert content.contains("# Status: UNCHANGED")    : "FAIL: missing # Status: UNCHANGED comment"
            log.info "✓ Status: UNCHANGED (correct)"
        }

    // Verify Case 3: WORSE
    POLISHING_SUMMARY3.out.summary
        .view { meta, tsv ->
            def content = tsv.text
            log.info "--- Case 3: WORSE ---"
            assert tsv.name.endsWith("_polishing_summary_mqc.tsv") : "FAIL: expected _polishing_summary.tsv suffix"
            assert content.contains("WORSE")                   : "FAIL: expected WORSE status"
            assert content.contains("# Status: WORSE")        : "FAIL: missing # Status: WORSE comment"
            log.info "✓ Status: WORSE (correct)"
        }

    POLISHING_SUMMARY.out.versions
        .view { versions ->
            log.info "✓ Version info: ${versions.name}"
        }
}

workflow.onComplete {
    println ""
    println "POLISHING_SUMMARY test complete. Results in: ${params.outdir}"
}
