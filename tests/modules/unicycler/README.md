# UNICYCLER Module Tests

## Purpose

Test that the UNICYCLER module correctly:
- Accepts Short (Illumina) and Long (Nanopore) reads.
- Optionally accepts an existing assembly.
- Constructs the correct command line.
- Renames and outputs files.

## Test Data

Uses standard test data in `tests/data/`.

## Running the Test

```bash
export NXF_OFFLINE=true
nextflow run tests/modules/unicycler/test_unicycler.nf -c nextflow.config -profile singularity,slurm
```
