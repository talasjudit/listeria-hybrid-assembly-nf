# COVERAGE_CHECK Module Tests

## Purpose

Test that the COVERAGE_CHECK module correctly:
- parses genome size
- calculates coverage for Illumina and Nanopore reads in parallel (using SeqKit)
- Branches passed and failed samples
- Generates a report file with status "PASSED" or "FAILED"

## Test Data

Test data is located at:

```
tests/data/
├── test_R1.fastq.gz        # Illumina Forward
├── test_R2.fastq.gz        # Illumina Reverse
└── test_nanopore.fastq.gz  # Nanopore long reads
```

## Running the Tests

Use a single test script (`test_coverage_check.nf`) for both scenarios.

### 1. Test Passing Scenario (Default)
This uses default thresholds (30x/20x), expecting the sample to **PASS**.

```bash
export NXF_OFFLINE=true
nextflow run tests/modules/coverage_check/test_coverage_check.nf -c nextflow.config -profile singularity,slurm
```
**Expected Output:** `✓ SUCCESS: Sample correctly PASSED QC.`

### 2. Test Failing Scenario
This uses the `fail.config` to set high thresholds (10,000x), expecting the sample to **FAIL**.

```bash
nextflow run tests/modules/coverage_check/test_coverage_check.nf \
    -c nextflow.config \
    -c tests/modules/coverage_check/fail.config \
    -profile singularity,slurm
```
**Expected Output:** `✓ SUCCESS: Sample correctly FAILED QC (as expected due to high thresholds).`

## Expected Outputs (Files)

In both cases, a report file is generated: `*_coverage_report.txt` containing the calculated coverage and the final status.
