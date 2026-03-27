# CLAUDE.md — Listeria Collaborative Hybrid Assembly Pipeline

## Project Goal

A **Nextflow DSL2 pipeline** for hybrid assembly of Listeria (and other bacterial)
genomes using Illumina short reads and Oxford Nanopore long reads. Target
repository: `github.com/talasjudit/listeria-hybrid-assembly-nf`.

The pipeline was converted from a working SLURM bash pipeline (BSUP-2555) and is
now a fully structured Nextflow project. A three-mode assembly strategy has been
implemented (unicycler / flye_unicycler / flye_polypolish) plus post-assembly
chromosome reorientation (dnaapler), circularity reporting, and reference comparison
(dnadiff × 2 + POLISHING_SUMMARY in flye_polypolish mode). All three modes passed
integration testing on BL07-034 (2026-03-25).

---

## Current File Structure

```
listeria-hybrid-assembly-nf/
├── main.nf                              # Entry point: help, version, INSTALL routing
├── nextflow.config                      # Params, profiles, manifest, plugins
├── nextflow_schema.json                 # Parameter validation schema (nf-schema)
├── CLAUDE.md                            # Project instructions for Claude Code
├── LICENSE
├── README.md
├── .github/
│   └── workflows/ci.yml                 # GitHub Actions CI (stub-run matrix: 3 assembly modes)
├── examples/
│   └── slurm_submission.slurm           # Example SLURM submission script
├── workflows/
│   ├── main.nf                          # Main pipeline orchestration (HYBRID_ASSEMBLY)
│   ├── install.nf                       # Container download workflow (storeDir)
│   └── README.md
├── modules/local/
│   ├── fastp.nf                         # Illumina QC + trimming
│   ├── porechop_abi.nf                  # Nanopore adapter removal
│   ├── filtlong.nf                      # Nanopore quality filtering
│   ├── coverage_check.nf                # Coverage validation gate (seqkit)
│   ├── circularity_check.nf             # Assembly circularity report (seqkit container)
│   ├── flye.nf                          # Long-read assembly (flye_unicycler + flye_polypolish modes)
│   ├── unicycler.nf                     # Hybrid assembly (unicycler + flye_unicycler modes)
│   ├── polypolish.nf                    # Illumina polishing of Flye assembly (flye_polypolish mode)
│   ├── dnaapler.nf                      # Chromosome reorientation to dnaA (all modes)
│   ├── dnadiff.nf                       # Assembly vs reference; used as DNADIFF_DRAFT + DNADIFF_POLISHED aliases
│   ├── polishing_summary.nf             # Before/after Polypolish comparison; IMPROVED/UNCHANGED/WORSE status
│   ├── checkm2.nf                       # Assembly completeness/contamination
│   ├── quast.nf                         # Assembly statistics
│   ├── multiqc.nf                       # Aggregated QC report
│   └── README.md
├── subworkflows/local/
│   ├── input_check.nf                   # Samplesheet parsing via nf-schema
│   ├── qc_nanopore.nf                   # Porechop ABI → Filtlong (sequential)
│   ├── assembly_unicycler.nf            # Unicycler hybrid (default mode)
│   ├── assembly_flye_unicycler.nf       # Unicycler with Flye scaffold
│   ├── assembly_polypolish.nf           # Polypolish on Flye assembly
│   ├── qc_assembly.nf                   # CheckM2 + QUAST (parallel)
│   └── README.md
├── conf/
│   ├── base.config                      # Per-process resources + check_max()
│   ├── slurm.config                     # Generic SLURM executor + offline mode
│   ├── qib.config                       # QIB/NBI partition mapping
│   ├── local.config                     # Local executor for development
│   ├── test.config                      # Test profile (reduced resources)
│   └── README.md
├── assets/
│   ├── schema_input.json                # nf-schema samplesheet validation
│   ├── multiqc_config.yaml              # MultiQC report customisation
│   └── README.md
├── tests/
│   ├── modules/
│   │   ├── fastp/test_fastp.nf
│   │   ├── porechop_abi/test_porechop_abi.nf
│   │   ├── filtlong/test_filtlong.nf
│   │   ├── coverage_check/test_coverage_check.nf  (+ fail.config)
│   │   ├── flye/test_flye.nf
│   │   ├── unicycler/test_unicycler.nf
│   │   ├── bwa_mem/test_bwa_mem.nf
│   │   ├── polypolish/test_polypolish.nf
│   │   ├── dnaapler/test_dnaapler.nf
│   │   ├── dnadiff/test_dnadiff.nf
│   │   ├── circularity_check/test_circularity_check.nf
│   │   ├── polishing_summary/test_polishing_summary.nf
│   │   ├── checkm2/test_checkm2.nf
│   │   └── quast/test_quast.nf
│   ├── subworkflows/
│   │   ├── input_check/test_input_check.nf
│   │   ├── qc_nanopore/test_qc_nanopore.nf
│   │   ├── qc_assembly/test_qc_assembly.nf
│   │   ├── assembly_unicycler/test_assembly_unicycler.nf
│   │   ├── assembly_flye_unicycler/test_assembly_flye_unicycler.nf
│   │   ├── assembly_polypolish/test_assembly_polypolish.nf
│   │   └── assembly_hybrid/test_assembly_hybrid.nf  # STALE — remove in commit 2
│   ├── integration/
│   │   ├── submit_integration_test.sh   # Submit all 3 modes as chained SLURM jobs
│   │   ├── run_pipeline_mode.slurm      # Per-mode SLURM job (receives mode via --export)
│   │   └── README.md
│   ├── data/
│   │   ├── samplesheet_test.csv              # Relative paths
│   │   ├── samplesheet_test_abs.csv          # Absolute paths (QIB HPC only)
│   │   ├── test_flye_assembly.fasta          # Flye draft assembly (unicycler, bwa_mem, polypolish, dnaapler, dnadiff tests)
│   │   ├── test_flye_info.txt                # Flye assembly_info.txt (circularity_check flye-format tests)
│   │   ├── test_unicycler_assembly.fasta     # Unicycler assembly (circularity_check, dnadiff tests)
│   │   ├── test_flye_draft.report            # Minimal dnadiff report, SNPs=542 (polishing_summary tests)
│   │   ├── test_polypolish.report            # Minimal dnadiff report, SNPs=142 (polishing_summary tests)
│   │   ├── test_R1_small.fastq.gz            # Illumina R1 10k-read subset (bwa_mem, polypolish, assembly_polypolish)
│   │   ├── test_R2_small.fastq.gz            # Illumina R2 10k-read subset (bwa_mem, polypolish, assembly_polypolish)
│   │   ├── download_test_data.sh             # Downloads full-size raw reads from ENA via wget
│   │   ├── generate_test_assemblies.slurm    # Regenerates committed assembly FASTAs from raw reads
│   │   └── README.md
│   └── README.md
└── docs/
    ├── usage.md
    ├── output.md
    └── parameters.md
```

---

## Architecture Decisions

### Assembly strategy: `params.assembly_mode` (string enum)

Three modes controlled by a single string parameter:

| Mode | Description |
|------|-------------|
| `unicycler` (default) | Unicycler hybrid (Illumina + Nanopore reads) |
| `flye_unicycler` | Flye long-read assembly → Unicycler with `--existing_long_read_assembly` |
| `flye_polypolish` | Flye long-read assembly → Polypolish (Illumina polishing) |

The mode is global (not per-sample). The old boolean `use_flye` param has been
**removed** and replaced with this enum. nf-schema validates allowed values at runtime.

### Post-assembly steps (all modes)

- **dnaapler** (`dnaapler all`): Reorients all assemblies to start at dnaA. Applied
  to all three modes for consistent output. Unicycler does its own rotation but
  dnaapler is applied anyway for uniformity on the `flye_unicycler` path.

- **dnadiff (× 2) + POLISHING_SUMMARY**: Only runs when `params.assembly_mode == 'flye_polypolish'`
  AND `params.reference` is provided. Two module alias invocations share the same `dnadiff.nf`:
  - `DNADIFF_DRAFT` — Flye draft vs reference; `ext.prefix = "${meta.id}_flye_draft"`
  - `DNADIFF_POLISHED` — Polypolish output vs reference; `ext.prefix = "${meta.id}_polypolish"`
  Each generates `*_dnadiff_mqc.tsv` with `# id: 'dnadiff_<prefix>'` (unique per alias so both
  appear as separate sections in MultiQC). Both reports are joined by sample and passed to
  `POLISHING_SUMMARY`, which writes `*_polishing_summary_mqc.tsv` with IMPROVED / UNCHANGED / WORSE
  status based on total variants (SNPs + indels). All outputs go to `qc/dnadiff/` and MultiQC.
  If reference is not provided in flye_polypolish mode, all three steps are skipped with a warning.

### Reference genome

Provided via `--reference /path/to/reference.fasta` (optional param, null by default).
Only used by the dnadiff module. Users point to their own file at runtime; not bundled.

### Assembly subworkflows (3 separate files, fully readable)

One subworkflow per assembly mode. The old `assembly_hybrid.nf` has been deleted.
Main workflow branches on `params.assembly_mode` and calls the appropriate subworkflow.

### Coverage check gate

`COVERAGE_CHECK` (seqkit) runs after QC and before assembly. Pass/fail branching:
- **Passed** → assembly
- **Failed** → logged as warning, excluded from assembly

Thresholds: `params.min_illumina_coverage` (default 30x), `params.min_nanopore_coverage` (default 20x).

### Circularity check (informational, not a gate)

`CIRCULARITY_CHECK` runs after assembly (before dnaapler) and reports whether contigs
are circular. It is purely informational — all samples continue regardless. A warning
is logged to the Nextflow log for any sample with a large linear contig (>= 500 kb).

The check auto-detects input format from file content:
- Unicycler FASTA: headers contain `circular=true/false`  → `SAMPLE_unicycler_circularity_mqc.tsv`
- Flye `assembly_info.txt`: col 4 = circ Y/N               → `SAMPLE_flye_draft_circularity_mqc.tsv`

Output format: TSV with columns `sample`, `source`, `contig`, `length_bp`, `circular`.
Final line is a `# Status: PASSED` or `# Status: WARNING` comment (ignored by TSV parsers,
used by the workflow status check, and compatible with MultiQC custom content).
Files use the `_mqc.tsv` suffix so MultiQC's `custom_content` module auto-detects them.

Per-mode behaviour:
| Mode | Input to circularity check | Reports per sample |
|------|----------------------------|--------------------|
| `unicycler` | Unicycler FASTA | `SAMPLE_unicycler_circularity_mqc.tsv` |
| `flye_unicycler` | Flye info + Unicycler FASTA (via `.mix()`) | both reports |
| `flye_polypolish` | Flye info only | `SAMPLE_flye_draft_circularity_mqc.tsv` |

For `flye_unicycler`, both files are fed to the same process via `.mix()`. The process
auto-detects which is which based on content and produces two separately-named outputs
that coexist in `results/qc/circularity/` regardless of mode. This means re-running
in a different mode doesn't overwrite the previous reports (different filenames).

Warning logging in `workflows/main.nf`:
```groovy
CIRCULARITY_CHECK.out.report
    .subscribe { meta, report ->
        if (report.text.contains("Status: WARNING")) {
            log.warn "Sample ${meta.id}: non-circular contig(s) detected - ..."
        }
    }
```

This differs from coverage check, which uses `.branch` to split passed/failed into
separate channels (because coverage check gates the pipeline; circularity does not).

### Publishing decisions (what goes to results/)

Decided against publishing intermediate assembly FASTAs to avoid disk bloat. Users
who need them can find them in the Nextflow work directory.

Assembly-mode-dependent outputs are published under `results/assembly/{assembly_mode}/`
and `results/qc/{assembly_mode}/` so that results from different modes coexist safely
in the same `--outdir`. Re-running with `-resume` and a different mode skips all
preprocessing steps automatically.

| Module | Published path | Published outputs | Not published |
|--------|---------------|-------------------|---------------|
| Porechop ABI | `qc/porechop/` | `*.log` | trimmed reads |
| Filtlong | `qc/filtlong/` | `*.log` | filtered reads |
| Flye | `assembly/{mode}/flye/` | `*_flye_info.txt`, `*_flye.log` | `*_flye.fasta` (intermediate) |
| Unicycler | `assembly/{mode}/unicycler/` | `*.gfa`, `*.log` | FASTA (intermediate, goes to dnaapler) |
| Polypolish | `assembly/flye_polypolish/polypolish/` | `*.log` | FASTA (intermediate, goes to dnaapler) |
| dnaapler | `assembly/{mode}/` | `*_dnaapler.fasta`, `*_dnaapler.log` | — |
| CIRCULARITY_CHECK | `qc/{mode}/circularity/` | `*_circularity_mqc.tsv` | — |
| DNADIFF_DRAFT | `qc/flye_polypolish/dnadiff/` | `*_flye_draft.report`, `*.delta`, `*_flye_draft_dnadiff_mqc.tsv` | derived delta files, `.snps` |
| DNADIFF_POLISHED | `qc/flye_polypolish/dnadiff/` | `*_polypolish.report`, `*.delta`, `*_polypolish_dnadiff_mqc.tsv` | derived delta files, `.snps` |
| POLISHING_SUMMARY | `qc/flye_polypolish/dnadiff/` | `*_polishing_summary_mqc.tsv` | — |
| CheckM2 | `qc/{mode}/checkm2/` | per-sample TSV + log | — |
| QUAST | `qc/{mode}/quast/` | per-sample TSV + HTML reports | — |
| MultiQC | `qc/{mode}/multiqc/` | `multiqc_report.html`, `multiqc_report_data/` | — |

### Flye `--meta` flag

`--meta` is for metagenomes (uneven coverage). **Not used** — not appropriate for
Listeria isolate assemblies. Decision confirmed; no action needed.

---

## Containers

| Tool | Version | SIF filename | Source |
|------|---------|-------------|--------|
| fastp | 1.0.1 | fastp-1.0.1.sif | `oras://ghcr.io/talasjudit/bsup-2555/fastp:1.0.1-1` |
| MultiQC | 1.31 | multiqc-1.31.sif | `oras://ghcr.io/talasjudit/bsup-2555/multiqc:1.31-1` |
| Porechop ABI | 0.5.1 | porechop_abi-0.5.1.sif | `oras://ghcr.io/talasjudit/bsup-2555/porechop_abi:0.5.1-1` |
| Filtlong | 0.3.1 | filtlong-0.3.1.sif | `oras://ghcr.io/talasjudit/bsup-2555/filtlong:0.3.1-1` |
| SeqKit | 2.12.0 | seqkit-2.12.0.sif | `oras://ghcr.io/talasjudit/bsup-2555/seqkit:2.12.0-1` |
| Flye | 2.9.6 | flye-2.9.6.sif | `oras://ghcr.io/talasjudit/bsup-2555/flye:2.9.6-1` |
| Unicycler | 0.5.1 | unicycler-0.5.1.sif | `docker://quay.io/biocontainers/unicycler:0.5.1--py39h746d604_5` |
| BWA | 0.7.19 | bwa-0.7.19.sif | `docker://quay.io/biocontainers/bwa:0.7.19--h577a1d6_1` |
| Polypolish | 0.6.1 | polypolish_0.6.1.sif | `docker://quay.io/biocontainers/polypolish:0.6.1--h3ab6199_0` |
| dnaapler | 1.3.0 | dnaapler-1.3.0.sif | `docker://quay.io/biocontainers/dnaapler:1.3.0--pyhdfd78af_0` |
| MUMmer (dnadiff) | 4.0.1 | mummer4-4.0.1.sif | `docker://quay.io/biocontainers/mummer4:4.0.1--pl5321h9948957_0` |
| CheckM2 | 1.1.0 | checkm2-1.1.0.sif | `oras://ghcr.io/talasjudit/bsup-2555/checkm2:1.1.0-1` |
| QUAST | 5.3.0 | quast-5.3.0.sif | `oras://ghcr.io/talasjudit/bsup-2555/quast:5.3.0-1` |

---

## What Has Been Implemented

### Core pipeline (complete)
- [x] `main.nf` entry point with help, version, INSTALL routing
- [x] `nextflow.config` — `assembly_mode` enum, `reference` param, all profiles
- [x] `nextflow_schema.json` — enum validation for `assembly_mode`, `reference` field
- [x] `workflows/install.nf` — all 12 containers with real URLs + storeDir caching
- [x] `workflows/main.nf` — 3-mode branching, Flye conditional, dnaapler + dnadiff + circularity check wired in
- [x] nf-schema plugin (`nf-schema@2.0.0`) for samplesheet validation

### Modules (15 total)
- [x] `fastp.nf` — Illumina QC + trimming
- [x] `porechop_abi.nf` — Nanopore adapter removal
- [x] `filtlong.nf` — Nanopore quality filtering
- [x] `coverage_check.nf` — Coverage validation gate
- [x] `circularity_check.nf` — Circularity report; auto-detects Unicycler/Flye format; TSV has embedded MultiQC headers; integration-tested
- [x] `flye.nf` — Long-read assembly; publishes info + log only (no FASTA); integration-tested
- [x] `unicycler.nf` — Hybrid assembly; publishes GFA + log only (no FASTA); integration-tested
- [x] `bwa_mem.nf` — BWA index + mem -a (R1/R2 independently); pre-processing for Polypolish; tested
- [x] `polypolish.nf` — Illumina polishing of Flye assembly; integration-tested
- [x] `dnaapler.nf` — Chromosome reorientation; output path confirmed flat; integration-tested
- [x] `dnadiff.nf` — Used via DNADIFF_DRAFT + DNADIFF_POLISHED aliases; generates `*_dnadiff_mqc.tsv`; integration-tested
- [x] `polishing_summary.nf` — Joins both dnadiff reports; before/after TSV with IMPROVED/UNCHANGED/WORSE; MultiQC-compatible; integration-tested
- [x] `checkm2.nf` — Assembly completeness/contamination; integration-tested
- [x] `quast.nf` — Assembly statistics; integration-tested
- [x] `multiqc.nf` — Aggregated QC report; integration-tested

### Subworkflows (6 total)
- [x] `input_check.nf`
- [x] `qc_nanopore.nf`
- [x] `assembly_unicycler.nf` — new
- [x] `assembly_flye_unicycler.nf` — new
- [x] `assembly_polypolish.nf` — new
- [x] `qc_assembly.nf`

### Configuration
- [x] `conf/base.config` — resource blocks for all 16 processes (including BWA_MEM and both DNADIFF aliases)
- [x] `conf/slurm.config`, `conf/qib.config` (unified `qib-compute` queue), `conf/local.config`
- [x] `conf/test.config` — all modules included in selectors; BWA_MEM in heavy group

### CI/CD
- [x] `.github/workflows/ci.yml` — matrix stub-run across all 3 assembly modes; `ci` profile in nextflow.config (local executor, singularity disabled)

### Tests
- [x] Module tests: fastp, porechop_abi, filtlong, coverage_check (+ fail.config), flye, unicycler, bwa_mem, polypolish, dnaapler, dnadiff, circularity_check, polishing_summary (IMPROVED/UNCHANGED/WORSE cases), checkm2, quast
- [x] Subworkflow tests: input_check, qc_nanopore, qc_assembly, assembly_unicycler, assembly_flye_unicycler, assembly_polypolish
- [x] Test data committed: test_flye_info.txt, test_unicycler_assembly.fasta, test_flye_draft.report, test_polypolish.report, test_R1_small.fastq.gz, test_R2_small.fastq.gz

### Documentation
- [x] `docs/parameters.md` — `--assembly_mode`, `--reference` documented; stale params fixed
- [x] `docs/usage.md` — full 3-mode section with comparison table; install command fixed
- [x] `docs/output.md` — rewritten for all current publishDir paths, modes, and circularity reports
- [x] `README.md` — mermaid diagram updated for 3 modes, repo URL and install command fixed

---

## What's Left To Do

### Test infrastructure
- [x] Integration test passed on QIB HPC — all 3 modes (BL07-034, 2026-03-25)
- [x] Module tests for all new modules (bwa_mem, circularity_check, dnaapler, dnadiff, polypolish, polishing_summary)
- [x] Subworkflow tests for assembly_unicycler, assembly_flye_unicycler, assembly_polypolish
- [x] CI/CD — GitHub Actions stub-run matrix, all 3 modes
- [ ] Integration test for new MultiQC sections (circularity, dnadiff x2, polishing_summary) — re-running with `-resume` (in progress 2026-03-26)
- [ ] assembly_unicycler and assembly_flye_unicycler subworkflow tests require full-size raw reads — download with `bash tests/data/download_test_data.sh`

### Resource tuning (after first real runs)
- `BWA_MEM`: currently 8 CPUs / 16 GB / 4h — tune after testing
- `POLYPOLISH`: currently 8 CPUs / 16 GB / 4h — tune after testing
- `DNAAPLER`: currently 4 CPUs / 8 GB / 1h — likely fine
- `DNADIFF_DRAFT` / `DNADIFF_POLISHED`: currently 4 CPUs / 8 GB / 2h — likely fine

### Other minor items
- [ ] MultiQC native support for Filtlong logs: verify `filtlong` sp: entry works in v1.31
- [ ] MultiQC Porechop ABI: no native module; consider custom content section if needed
- [ ] Consider publishDir for Filtlong/Porechop output reads (currently only logs published)

---

## Gotchas and Known Issues

### Stub run: COVERAGE_CHECK stub writes "Status: PASSED"
The `COVERAGE_CHECK` stub block writes `Status: PASSED` to the report file. This is
required because the branch operator evaluates file content (`report.text.contains("Status: PASSED")`).
An empty stub file would route all samples to the failed branch, causing downstream
processes to be silently skipped in CI. The stub must stay non-empty.

### Stale test: tests/subworkflows/assembly_hybrid/
This directory references the now-deleted `assembly_hybrid.nf`. Do not run it.
The file contains a comment explaining the replacement. The 3 new subworkflow tests
are in `assembly_unicycler/`, `assembly_flye_unicycler/`, `assembly_polypolish/`.

### Partial test FASTQ files in repo
`test_R1_small.fastq.gz` and `test_R2_small.fastq.gz` (10k subsampled pairs) are committed
and used by BWA_MEM, POLYPOLISH, and ASSEMBLY_POLYPOLISH tests.
Full-size `test_R1.fastq.gz`, `test_R2.fastq.gz`, `test_nanopore.fastq.gz` are gitignored.
Download them with `bash tests/data/download_test_data.sh` before running unicycler/flye tests.

### publishDir is assembly-mode-namespaced
All assembly-dependent outputs (flye, unicycler, polypolish, dnaapler, checkm2, quast,
multiqc) are published under `assembly/{mode}/` or `qc/{mode}/`. Re-running with a
different `--assembly_mode` and `-resume` is safe: preprocessing steps are cached and
mode-specific results coexist in the same `--outdir`.

### dnaapler output path confirmed flat in v1.3.0
`dnaapler all` outputs `{outdir}/{prefix}_reoriented.fasta` (not nested). The `mv` in
the script block is correct as written.

### `samplesheet_test_abs.csv` has hardcoded QIB paths
Only works on QIB HPC. Use `samplesheet_test.csv` for portable testing.

### Porechop ABI tmp directory workaround
`porechop_abi.nf` creates `mkdir -p tmp && chmod 777 tmp` before running.
Required for Singularity --no-home compatibility. Do not remove.

### Coverage check uses `bc` for float arithmetic
Available in the seqkit container. Worth noting if the container is ever swapped.

### `workflow.failOnError = false`
Pipeline continues past failures (intentional for batch processing). Check the
execution trace for individual sample failures.

### MultiQC channel collection
When adding new modules, their QC outputs must be mixed into `ch_multiqc_files` in
`workflows/main.nf` using `.map { meta, file -> file }` pattern before `.collect()`.

### MultiQC custom_content: `_mqc` suffix is required
MultiQC's `custom_content` module only auto-detects files whose name ends in `_mqc.{ext}`
(e.g. `_mqc.tsv`). Embedded `# id:` headers are NOT sufficient on their own. All custom
TSV outputs (circularity, polishing_summary) must use the `_mqc.tsv` suffix. The output
glob in the process definition must match — e.g. `path("*_circularity_mqc.tsv")`. The
stub must also touch the `_mqc.tsv` filename, not a plain `.tsv`, or Nextflow will fail
to find the output file in CI stub runs.

### Circularity check does not gate the pipeline
Unlike coverage check (which excludes failed samples from assembly), circularity check
is informational only. All samples proceed to dnaapler regardless. Warnings appear in
the Nextflow log and in the published report files.

---

## Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | (required) | Samplesheet CSV path |
| `--outdir` | `results` | Output directory |
| `--assembly_mode` | `unicycler` | Assembly strategy: `unicycler` \| `flye_unicycler` \| `flye_polypolish` |
| `--genome_size` | `3m` | Expected genome size (for Flye and coverage check) |
| `--reference` | `null` | Reference FASTA for dnadiff (flye_polypolish only, optional) |
| `--min_read_length` | `6000` | Filtlong minimum read length |
| `--filtlong_keep_percent` | `95` | Filtlong quality filter |
| `--min_illumina_coverage` | `30` | Coverage gate threshold (Illumina) |
| `--min_nanopore_coverage` | `20` | Coverage gate threshold (Nanopore) |
| `--singularity_cachedir` | `${launchDir}/singularity_cache` | Container cache |
| `--max_cpus` | `12` | Max CPUs per process |
| `--max_memory` | `128.GB` | Max memory per process |
| `--max_time` | `24.h` | Max time per process |

---

## Resource Allocations (from conf/base.config)

| Process | CPUs | Memory | Time | Notes |
|---------|------|--------|------|-------|
| FASTP | 6 × attempt | 16 GB × attempt | 4h × attempt | |
| PORECHOP_ABI | 6 × attempt | 16 GB × attempt | 4h × attempt | |
| FILTLONG | 4 | 8 GB × attempt | 2h | Single-threaded |
| COVERAGE_CHECK | 1 (default) | 4 GB (default) | 1h (default) | |
| CIRCULARITY_CHECK | 1 | 1 GB | 30m | Minimal; bash/awk on small files |
| FLYE | 12 × attempt | 32 GB × attempt | 24h × attempt | |
| UNICYCLER | 12 × attempt | 32 GB × attempt | 24h × attempt | |
| BWA_MEM | 8 × attempt | 16 GB × attempt | 4h × attempt | Two calls (R1/R2 independently); TODO: tune |
| POLYPOLISH | 8 × attempt | 16 GB × attempt | 4h × attempt | TODO: tune |
| DNAAPLER | 4 | 8 GB × attempt | 1h | Fast; MMseqs2 protein search |
| DNADIFF_DRAFT | 4 | 8 GB × attempt | 2h | Flye draft vs reference |
| DNADIFF_POLISHED | 4 | 8 GB × attempt | 2h | Polypolish output vs reference |
| POLISHING_SUMMARY | 1 | 1 GB | 30m | bash/awk on two report files |
| CHECKM2 | 8 × attempt | 16 GB × attempt | 6h × attempt | |
| QUAST | 4 | 8 GB × attempt | 2h | |
| MULTIQC | 4 | 8 GB × attempt | 2h | |

---

## Background Context

### Why three assembly paths

Investigation of 4 failed circularisation samples (BL86-009, BL86-012, BL87-019,
BL87-023) showed that high-copy-number repeats in the SPAdes short-read graph
prevented Unicycler from bridging and circularising. Flye alone circularised all 4
cleanly. The `--existing_long_read_assembly` mode (Flye+Unicycler scaffold)
provided little to no improvement for these cases.

### Why dnaapler on all modes

Unicycler performs its own dnaA reorientation, but on the `flye_unicycler` path
Unicycler receives an existing assembly and may skip rotation. Applying dnaapler
to all modes ensures uniform output orientation. Overhead is negligible (~3 s/genome).

### Why intermediate FASTAs are not published

Publishing all intermediate FASTAs (Flye draft, Unicycler output, Polypolish output)
would significantly increase disk usage for large batches. The final dnaapler FASTA
is the only assembly users need. All intermediates remain in the Nextflow work directory
and can be recovered with `nextflow log` if needed.

### Why circularity is checked before dnaapler

dnaapler reorients the assembly but does not change contig circularity. Checking
before vs after dnaapler makes no difference for circularity. The check is placed
before dnaapler because the Unicycler FASTA headers (which encode circularity) are
the input to dnaapler — checking before ensures we read the original headers.

### Decided against
- **Hybracter** integration
- **dnadiff without reference** — comparing unpolished vs polished is insufficient;
  a reference is required for meaningful QC
- **Flye `--meta` flag** — for metagenomes only; not appropriate for isolate assemblies
