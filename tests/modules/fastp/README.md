# FASTP Module Tests

## Purpose

Test that the FASTP module correctly:
- Trims adapters from paired-end Illumina reads
- Filters low-quality bases
- Corrects bases in overlapping regions
- Generates QC reports (JSON and HTML)

## Test Data

Test data is located at:

```
tests/data/
├── test_R1.fastq.gz  # Forward reads
└── test_R2.fastq.gz  # Reverse reads
```

## Expected Outputs

After running the test, verify these outputs:

1. **Trimmed reads:**
   - `test_sample_R1_trimmed.fastq.gz`
   - `test_sample_R2_trimmed.fastq.gz`
   - Should be smaller than input (adapters removed)
   - Should be non-empty

2. **JSON report:**
   - `test_sample.json`
   - Contains QC metrics for MultiQC

3. **HTML report:**
   - `test_sample.html`
   - Interactive visualization (open in browser)

4. **Version info:**
   - `versions.yml`
   - Contains fastp version

## Running the Test

**Important:** Run from the project root directory.

```bash
# If HPC has no internet access
export NXF_OFFLINE=true

# Run the test
nextflow run tests/modules/fastp/test_fastp.nf -c nextflow.config -profile singularity,slurm
```

With resume:

```bash
nextflow run tests/modules/fastp/test_fastp.nf -c nextflow.config -profile singularity,slurm -resume
```

## Verification Checklist

- [ ] Test completes without errors
- [ ] Trimmed reads produced (non-empty)
- [ ] JSON report produced
- [ ] HTML report produced
- [ ] versions.yml contains fastp version

## Troubleshooting

### Container not found

```
Error: could not open image .../singularity_cache/fastp-1.0.1.sif
Solution: 
  - Run from project root, not from test directory
  - Ensure containers are installed: nextflow run main.nf -entry INSTALL -profile singularity
```

### Test data not found

```
Error: Test data not found!
Solution: Ensure tests/data/test_R1.fastq.gz and test_R2.fastq.gz exist
```

### Hanging on startup

```
Cause: Nextflow trying to contact plugin registry on offline HPC
Solution: export NXF_OFFLINE=true before running
```
