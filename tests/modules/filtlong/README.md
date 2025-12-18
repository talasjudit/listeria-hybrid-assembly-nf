# FILTLONG Module Tests

## Purpose

Test that the FILTLONG module correctly:
- Filters Nanopore reads by length (min_length)
- Filters reads by quality (keep_percent)
- Generates log file with filtering statistics

## Test Data

Test data is located at:

```
tests/data/
└── test_nanopore.fastq.gz  # Nanopore long reads
```

## Expected Outputs

After running the test, verify these outputs:

1. **Filtered reads:**
   - `test_sample_filtlong.fastq.gz`
   - Should be non-empty
   - Contains quality-filtered Nanopore reads

2. **Log file:**
   - `test_sample_filtlong.log`
   - Contains filtering statistics (reads kept vs discarded)

3. **Version info:**
   - `versions.yml`
   - Contains filtlong version

## Running the Test

**Important:** Run from the project root directory.

```bash
# If HPC has no internet access
export NXF_OFFLINE=true

# Run the test
nextflow run tests/modules/filtlong/test_filtlong.nf -c nextflow.config -profile singularity,slurm
```

With resume:

```bash
nextflow run tests/modules/filtlong/test_filtlong.nf -c nextflow.config -profile singularity,slurm -resume
```

## Verification Checklist

- [ ] Test completes without errors
- [ ] Filtered reads produced (non-empty)
- [ ] Log file produced with filtering stats
- [ ] versions.yml contains filtlong version

## Troubleshooting

### Container not found

```
Error: could not open image .../singularity_cache/filtlong-0.3.0.sif
Solution: 
  - Run from project root, not from test directory
  - Ensure containers are installed: nextflow run main.nf -entry INSTALL -profile singularity
```

### Test data not found

```
Error: Test data not found!
Solution: Ensure tests/data/test_nanopore.fastq.gz exists
```

### Hanging on startup

```
Cause: Nextflow trying to contact plugin registry on offline HPC
Solution: export NXF_OFFLINE=true before running
```
