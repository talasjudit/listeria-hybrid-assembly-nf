# Local Modules

Custom process modules for the hybrid assembly pipeline.

## Module List

| Module | Tool | Version | Purpose |
|--------|------|---------|---------|
| `fastp.nf` | fastp | 1.0.1 | Illumina read QC and trimming |
| `porechop_abi.nf` | Porechop ABI | 0.5.1 | Nanopore adapter removal |
| `filtlong.nf` | Filtlong | 0.3.1 | Nanopore quality filtering |
| `coverage_check.nf` | SeqKit | 2.12.0 | Coverage validation gate |
| `circularity_check.nf` | bash/awk | - | Assembly circularity report (TSV, MultiQC-compatible) |
| `flye.nf` | Flye | 2.9.6 | Long-read de novo assembly |
| `unicycler.nf` | Unicycler | 0.5.1 | Hybrid assembly |
| `bwa_mem.nf` | BWA | 0.7.19 | Index + paired-end alignment for Polypolish pre-processing |
| `polypolish.nf` | Polypolish | 0.6.1 | Illumina polishing of Flye assembly |
| `dnaapler.nf` | dnaapler | 1.3.0 | Chromosome reorientation to dnaA |
| `dnadiff.nf` | MUMmer4 | 4.0.1 | Assembly vs reference comparison; used as DNADIFF_DRAFT + DNADIFF_POLISHED aliases |
| `polishing_summary.nf` | bash/awk | - | Before/after Polypolish comparison; IMPROVED/UNCHANGED/WORSE status |
| `checkm2.nf` | CheckM2 | 1.1.0 | Assembly completeness and contamination |
| `quast.nf` | QUAST | 5.3.0 | Assembly statistics |
| `multiqc.nf` | MultiQC | 1.31 | Aggregated QC report |

## Publishing

Intermediate assembly FASTAs are not published. Only the final dnaapler FASTA is written to `results/`.
See `docs/output.md` for the full list of published files per module.

## Resources

Resource allocations (CPU, memory, time) are defined in `conf/base.config`.
Containers are defined per-module using `params.singularity_cachedir`.
