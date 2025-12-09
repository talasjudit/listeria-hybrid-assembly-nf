# PORECHOP_ABI Module Tests

## Purpose

Test that the PORECHOP_ABI module correctly:
- Detects adapters using ab initio method
- Removes adapters from Nanopore reads
- Generates log file with adapter detection info

## Test Data

Test data is located at:

```
tests/data/
└── test_nanopore.fastq.gz  # Nanopore long reads
```

## Expected Outputs

After running the test, verify these outputs:

1. **Trimmed reads:**
   - `test_sample_porechop.fastq.gz`
   - Should be non-empty
   - Contains adapter-trimmed Nanopore reads

2. **Log file:**
   - `test_sample_porechop.log`
   - Contains adapter detection statistics

3. **Version info:**
   - `versions.yml`
   - Contains porechop_abi version

## Running the Test

**Important:** Run from the project root directory.

```bash
# If HPC has no internet access
export NXF_OFFLINE=true

# Run the test
nextflow run tests/modules/porechop_abi/test_porechop_abi.nf -c nextflow.config -profile singularity,slurm
```

With resume:

```bash
nextflow run tests/modules/porechop_abi/test_porechop_abi.nf -c nextflow.config -profile singularity,slurm -resume
```

## Verification Checklist

- [ ] Test completes without errors
- [ ] Trimmed reads produced (non-empty)
- [ ] Log file produced with adapter stats
- [ ] versions.yml contains porechop_abi version

## Troubleshooting

### Container not found

```
Error: could not open image .../singularity_cache/porechop_abi-0.5.0.sif
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
