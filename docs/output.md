# Output Documentation

This document describes the files and directories produced by the pipeline.

## Output Directory Structure

Assembly-mode-dependent outputs are organised under a `{assembly_mode}/` subdirectory so that results from different modes coexist safely in the same `--outdir`. Re-running with a different mode and `-resume` will skip all preprocessing steps (reads are unchanged) and only re-run the assembly and downstream steps.

```
results/
├── qc/
│   ├── fastp/                          # Illumina QC reports (per sample, all modes)
│   ├── porechop/                       # Nanopore adapter trimming logs (per sample, all modes)
│   ├── filtlong/                       # Nanopore quality filtering logs (per sample, all modes)
│   ├── coverage/                       # Coverage gate reports (per sample, all modes)
│   ├── unicycler/
│   │   ├── circularity/                # Assembly circularity reports (unicycler mode)
│   │   ├── checkm2/                    # Assembly completeness (unicycler mode)
│   │   ├── quast/                      # Assembly statistics (unicycler mode)
│   │   └── multiqc/                    # Aggregated QC report (unicycler mode)
│   ├── flye_unicycler/
│   │   ├── circularity/                # Assembly circularity reports (flye_unicycler mode)
│   │   ├── checkm2/
│   │   ├── quast/
│   │   └── multiqc/
│   └── flye_polypolish/
│       ├── circularity/                # Assembly circularity reports (flye_polypolish mode)
│       ├── dnadiff/                    # Reference comparison (--reference only)
│       ├── checkm2/
│       ├── quast/
│       └── multiqc/
├── assembly/
│   ├── unicycler/
│   │   ├── unicycler/                  # Unicycler graph + log (unicycler mode)
│   │   └── SAMPLE_dnaapler.fasta       # Final assembly (unicycler mode)
│   ├── flye_unicycler/
│   │   ├── flye/                       # Flye info + log
│   │   ├── unicycler/                  # Unicycler graph + log
│   │   └── SAMPLE_dnaapler.fasta       # Final assembly (flye_unicycler mode)
│   └── flye_polypolish/
│       ├── flye/                       # Flye info + log
│       ├── polypolish/                 # Polypolish log
│       └── SAMPLE_dnaapler.fasta       # Final assembly (flye_polypolish mode)
└── pipeline_info/                      # Nextflow execution reports
```

The final genome assembly for each sample is `results/assembly/{assembly_mode}/SAMPLE_dnaapler.fasta`.
Intermediate assembly FASTAs are not published; they remain in the Nextflow work directory if needed.

## Output Descriptions

### FastP - Illumina QC

**Directory:** `results/qc/fastp/`

One JSON and one HTML report per sample. Open the HTML in a browser to review read quality, adapter content, and filtering statistics. The JSON is also collected by MultiQC.

### Porechop ABI - Nanopore Adapter Trimming

**Directory:** `results/qc/porechop/`

One log file per sample showing the number of reads processed and adapters detected and removed. Also collected by MultiQC.

### Filtlong - Nanopore Quality Filtering

**Directory:** `results/qc/filtlong/`

One log file per sample showing filtering statistics (reads kept, bases retained). Also collected by MultiQC.

### Coverage Check

**Directory:** `results/qc/coverage/`

One text report per sample stating whether the sample passed or failed the coverage thresholds (default: 30x Illumina, 20x Nanopore). Samples that fail are excluded from assembly with a warning in the pipeline log.

### Circularity Check

**Directory:** `results/qc/{assembly_mode}/circularity/`

Reports produced depend on the assembly mode:

| Mode | Reports per sample |
|------|--------------------|
| `unicycler` | `SAMPLE_unicycler_circularity.tsv` |
| `flye_unicycler` | `SAMPLE_flye_draft_circularity.tsv` + `SAMPLE_unicycler_circularity.tsv` |
| `flye_polypolish` | `SAMPLE_flye_draft_circularity.tsv` |

Each report is a TSV with columns `sample`, `source`, `contig`, `length_bp`, `circular` — one row per contig. The final line is a comment (`# Status: PASSED` or `# Status: WARNING`) indicating whether any large contig (>= 500 kb) is linear. The TSV format is human-readable and compatible with MultiQC custom content.

For `flye_unicycler` mode, having both reports lets you see whether Flye circularised the genome and whether Unicycler preserved that circularity after polishing.

Any WARNING is also printed to the pipeline log at runtime.

### Flye - Long-Read Assembly (info and log)

**Directory:** `results/assembly/{assembly_mode}/flye/`

Present only in `flye_unicycler` and `flye_polypolish` modes.

Files per sample:
- `SAMPLE_flye_info.txt` - Flye contig table: length, coverage, circularity (Y/N), repeat status
- `SAMPLE_flye.log` - Assembly log

The Flye FASTA itself is not published (it is an intermediate file used by Unicycler or Polypolish). It remains in the Nextflow work directory.

### Unicycler - Assembly Graph and Log

**Directory:** `results/assembly/{assembly_mode}/unicycler/`

Present only in `unicycler` and `flye_unicycler` modes.

Files per sample:
- `SAMPLE_unicycler_graph.gfa` - Assembly graph (useful for inspecting assembly structure)
- `SAMPLE_unicycler.log` - Assembly log

The Unicycler FASTA is not published here because it undergoes further processing by dnaapler. The final FASTA is at `results/assembly/{assembly_mode}/SAMPLE_dnaapler.fasta`.

### Polypolish - Polishing Log

**Directory:** `results/assembly/flye_polypolish/polypolish/`

Present only in `flye_polypolish` mode.

Files per sample:
- `SAMPLE_polypolish.log` - Polishing log

The Polypolish FASTA is not published here; the final FASTA is at `results/assembly/flye_polypolish/SAMPLE_dnaapler.fasta`.

### dnaapler - Final Assembly

**Directory:** `results/assembly/{assembly_mode}/`

The final assembly for all modes, reoriented so the chromosome starts at the dnaA gene. This is the file to use for all downstream analysis.

Files per sample:
- `SAMPLE_dnaapler.fasta` - Final reoriented assembly
- `SAMPLE_dnaapler.log` - Reorientation log

### CheckM2 - Assembly Completeness

**Directory:** `results/qc/{assembly_mode}/checkm2/`

Files per sample:
- `SAMPLE_checkm2_summary.tsv` - Completeness and contamination estimates
- `SAMPLE_checkm2.log` - Analysis log

Key metrics:

| Metric | Good | Acceptable | Problematic |
|--------|------|------------|-------------|
| Completeness | >95% | 90-95% | <80% |
| Contamination | <2% | 2-5% | >5% |

### QUAST - Assembly Statistics

**Directory:** `results/qc/{assembly_mode}/quast/`

Files per sample:
- `SAMPLE_quast_summary.tsv` - Assembly statistics table
- `SAMPLE_quast/report.html` - Interactive report
- `SAMPLE_quast/icarus.html` - Icarus contig viewer
- `SAMPLE_quast.log` - Analysis log

Key metrics to check:

| Metric | Description |
|--------|-------------|
| # contigs | Number of contigs (fewer is better) |
| Total length | Assembly size (should match expected genome size) |
| N50 | Half the assembly is in contigs at least this size |
| Largest contig | Should be close to chromosome size |
| GC (%) | Should match the expected value for the organism |

### dnadiff - Reference Comparison and Polishing Summary

**Directory:** `results/qc/flye_polypolish/dnadiff/`

Present only when `--assembly_mode flye_polypolish` and `--reference` are both provided. dnadiff runs twice, comparing both the Flye draft and the Polypolish output against the reference.

Files per sample:
- `SAMPLE_flye_draft.report` - MUMmer dnadiff report (Flye draft vs reference)
- `SAMPLE_flye_draft.delta` - Alignment delta file
- `SAMPLE_flye_draft_dnadiff_mqc.tsv` - MultiQC table (identity, aligned %, SNPs, indels)
- `SAMPLE_polypolish.report` - MUMmer dnadiff report (Polypolish output vs reference)
- `SAMPLE_polypolish.delta` - Alignment delta file
- `SAMPLE_polypolish_dnadiff_mqc.tsv` - MultiQC table (identity, aligned %, SNPs, indels)
- `SAMPLE_polishing_summary.tsv` - Before/after comparison with IMPROVED / UNCHANGED / WORSE status

The polishing summary compares total variant counts (SNPs + indels) between the draft and polished assemblies. IMPROVED means Polypolish reduced variants relative to the reference.

### MultiQC - Aggregated Report

**Directory:** `results/qc/{assembly_mode}/multiqc/`

- `multiqc_report.html` - Interactive report aggregating results from: fastp, Filtlong, QUAST, CheckM2, circularity check, dnadiff (x2, flye_polypolish only), and polishing summary (flye_polypolish only). Open this first.
- `multiqc_report_data/` - Raw data behind the report

### Pipeline Info

**Directory:** `results/pipeline_info/`

Nextflow execution reports generated automatically:
- `execution_timeline.html` - Timeline of all processes
- `execution_report.html` - Resource usage summary
- `execution_trace.txt` - Detailed trace log
- `pipeline_dag.svg` - Workflow diagram

## Quality Control Checklist

After the pipeline completes:

- All samples present in `results/assembly/{assembly_mode}/` as `SAMPLE_dnaapler.fasta`
- All circularity reports in `results/qc/{assembly_mode}/circularity/` show `# Status: PASSED`
- CheckM2 completeness >90% for all samples
- CheckM2 contamination <5% for all samples
- QUAST N50 and total length consistent with expected genome size
- For `flye_polypolish` with `--reference`: polishing summary shows IMPROVED for all samples
- No failed processes in `results/pipeline_info/execution_trace.txt`

## See Also

- [Usage Guide](usage.md)
- [Parameters Reference](parameters.md)
- [Main README](../README.md)
