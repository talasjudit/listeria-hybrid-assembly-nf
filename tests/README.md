# Tests

## Directory Structure

```
tests/
├── modules/                        # Unit tests for individual processes
│   ├── fastp/
│   ├── porechop_abi/
│   ├── filtlong/
│   ├── coverage_check/             (+ fail.config for threshold test)
│   ├── flye/
│   ├── unicycler/
│   ├── checkm2/
│   ├── quast/
│   ├── bwa_mem/
│   ├── polypolish/
│   ├── dnaapler/
│   ├── dnadiff/
│   ├── circularity_check/
│   └── polishing_summary/
├── subworkflows/
│   ├── input_check/
│   ├── qc_nanopore/
│   ├── qc_assembly/
│   ├── assembly_unicycler/         (requires raw reads)
│   ├── assembly_flye_unicycler/    (requires raw reads)
│   ├── assembly_polypolish/        (committed data only)
│   └── assembly_hybrid/            STALE - do not run
├── integration/
│   └── test_full_pipeline.nf
└── data/                           see tests/data/README.md
```

## Test Data Requirements

Tests are split by data availability:

**Committed data only (run any time):**
- `bwa_mem`, `polypolish` (via BWA_MEM chain), `dnaapler`, `dnadiff`, `circularity_check`, `polishing_summary`
- `assembly_polypolish` subworkflow
- Uses: `test_flye_assembly.fasta`, `test_flye_info.txt`, `test_unicycler_assembly.fasta`,
  `test_R1_small.fastq.gz`, `test_R2_small.fastq.gz`, `test_flye_draft.report`, `test_polypolish.report`

**Require raw reads staged to `tests/data/`:**
- `fastp`, `porechop_abi`, `filtlong`, `flye`, `unicycler`, `coverage_check`
- `qc_nanopore`, `assembly_unicycler`, `assembly_flye_unicycler`
- Copy from `/qib/scratch/users/wel24kif/Listeria_test/` before running:
  ```bash
  cp /qib/scratch/users/wel24kif/Listeria_test/BL07-034.fastq.gz tests/data/test_nanopore.fastq.gz
  cp /qib/scratch/.../PID-2142-BL07-034_S703_R1_001.fastq.gz tests/data/test_R1.fastq.gz
  cp /qib/scratch/.../PID-2142-BL07-034_S703_R2_001.fastq.gz tests/data/test_R2.fastq.gz
  ```

## Running Tests

All commands run from the project root with `-profile singularity,qib`.

### Modules (committed data)

```bash
nextflow run tests/modules/bwa_mem/test_bwa_mem.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/modules/polypolish/test_polypolish.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/modules/dnaapler/test_dnaapler.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/modules/dnadiff/test_dnadiff.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/modules/circularity_check/test_circularity_check.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/modules/polishing_summary/test_polishing_summary.nf \
    -c nextflow.config -profile singularity,qib
```

### Modules (require raw reads)

```bash
nextflow run tests/modules/fastp/test_fastp.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/modules/flye/test_flye.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/modules/unicycler/test_unicycler.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/modules/coverage_check/test_coverage_check.nf \
    -c nextflow.config -profile singularity,qib

# Coverage FAIL case (expects failure at high threshold):
nextflow run tests/modules/coverage_check/test_coverage_check.nf \
    -c nextflow.config -c tests/modules/coverage_check/fail.config \
    -profile singularity,qib
```

### Subworkflows

```bash
# Committed data only:
nextflow run tests/subworkflows/assembly_polypolish/test_assembly_polypolish.nf \
    -c nextflow.config -profile singularity,qib

# Require raw reads:
nextflow run tests/subworkflows/assembly_unicycler/test_assembly_unicycler.nf \
    -c nextflow.config -profile singularity,qib

nextflow run tests/subworkflows/assembly_flye_unicycler/test_assembly_flye_unicycler.nf \
    -c nextflow.config -profile singularity,qib
```

### Stub run (no data or containers required)

Validates pipeline structure and channel logic for all 3 modes. Processes after
`COVERAGE_CHECK` will show `-` (not run) because the stub produces an empty report
file that the branch logic cannot match — this is expected and correct.

```bash
for mode in unicycler flye_unicycler flye_polypolish; do
    nextflow run main.nf -stub -profile singularity,qib \
        --assembly_mode $mode \
        --input tests/data/samplesheet_test.csv \
        --outdir results_stub_${mode}
done
```

## Test Status

| Test | Data needed | Status |
|------|------------|--------|
| fastp | raw reads | passed |
| porechop_abi | raw reads | passed |
| filtlong | raw reads | passed |
| coverage_check (pass + fail) | raw reads | passed |
| flye | raw reads | passed |
| unicycler | raw reads | passed |
| checkm2 | flye assembly | passed |
| quast | flye assembly | passed |
| bwa_mem | small reads | passed |
| polypolish | small reads | passed |
| dnaapler | flye assembly | passed |
| dnadiff | flye + unicycler assembly | passed |
| circularity_check | flye info + unicycler fasta | passed |
| polishing_summary | dnadiff report files | passed |
| assembly_polypolish | small reads | passed |
| assembly_unicycler | raw reads | passed |
| assembly_flye_unicycler | raw reads | passed |
| stub run (all 3 modes) | none | passed |
