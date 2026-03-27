# Workflows

## main.nf

Orchestrates the complete hybrid assembly pipeline (`HYBRID_ASSEMBLY` workflow).

### Pipeline Steps

1. `INPUT_CHECK` - Parse and validate samplesheet
2. `FASTP` - Illumina read QC and trimming
3. `QC_NANOPORE` - Nanopore adapter removal and quality filtering
4. `COVERAGE_CHECK` - Coverage gate (excludes low-coverage samples from assembly)
5. Assembly - one of three subworkflows based on `--assembly_mode`:
   - `ASSEMBLY_UNICYCLER` (default)
   - `ASSEMBLY_FLYE_UNICYCLER`
   - `ASSEMBLY_POLYPOLISH`
6. `CIRCULARITY_CHECK` - Reports contig circularity (informational, does not gate pipeline)
7. `DNAAPLER` - Reorients assembly to start at dnaA
8. `DNADIFF_DRAFT` + `DNADIFF_POLISHED` + `POLISHING_SUMMARY` - Flye draft vs reference, Polypolish output vs reference, before/after comparison (flye_polypolish + --reference only)
9. `QC_ASSEMBLY` - CheckM2 completeness and QUAST statistics (parallel)
10. `MULTIQC` - Aggregated QC report

### Usage

```bash
# Default mode
nextflow run main.nf -profile qib --input samplesheet.csv

# Alternative assembly modes
nextflow run main.nf -profile qib --input samplesheet.csv --assembly_mode flye_unicycler
nextflow run main.nf -profile qib --input samplesheet.csv --assembly_mode flye_polypolish

# With reference for dnadiff (flye_polypolish only)
nextflow run main.nf -profile qib --input samplesheet.csv \
    --assembly_mode flye_polypolish --reference /path/to/reference.fasta
```

See `docs/usage.md` for full documentation.

---

## install.nf

Downloads all Singularity containers required by the pipeline.

### Usage

```bash
nextflow run main.nf -entry INSTALL -profile singularity
```

Run this once before the first pipeline run, from a node with internet access.
Containers are cached in `params.singularity_cachedir` (default: `${launchDir}/singularity_cache`).
Already-downloaded containers are skipped automatically.
