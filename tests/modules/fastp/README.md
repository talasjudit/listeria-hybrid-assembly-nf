# FASTP Module Tests

## Purpose

Test that the FASTP module correctly:
- Trims adapters from paired-end Illumina reads
- Filters low-quality bases
- Corrects bases in overlapping regions
- Generates QC reports (JSON and HTML)

## Test Data

### Required Files

```
tests/modules/fastp/test_data/
├── test_R1.fastq.gz  # Forward reads (small test set)
└── test_R2.fastq.gz  # Reverse reads (small test set)
```

### TODO: Add Test Data

Test data should be:
- Paired-end Illumina reads
- ~10,000 read pairs (20,000 total reads)
- Gzipped FASTQ format
- Representative of real sequencing data

## Expected Outputs

After running the test, verify these outputs:

1. **Trimmed reads:**
   - `test_sample_R1_trimmed.fastq.gz`
   - `test_sample_R2_trimmed.fastq.gz`
   - Should be smaller than input (adapters removed)
   - Should be non-empty
   - Should be valid FASTQ.gz format

2. **JSON report:**
   - `test_sample.json`
   - Contains QC metrics in JSON format
   - Should include: total reads, filtered reads, adapter stats

3. **HTML report:**
   - `test_sample.html`
   - Interactive HTML visualization
   - Can be opened in a browser

4. **Version info:**
   - `versions.yml`
   - Contains fastp version

## Running the Test

### From test directory:

```bash
cd tests/modules/fastp
nextflow run test_fastp.nf -profile test,singularity
```

### From project root:

```bash
nextflow run tests/modules/fastp/test_fastp.nf -profile test,singularity
```

### With resume:

```bash
nextflow run test_fastp.nf -profile test,singularity -resume
```

## Verification Checklist

After the test runs, verify:

- [ ] Test completes without errors
- [ ] All 4 output types are produced
- [ ] Output files are non-empty
- [ ] Trimmed reads are valid FASTQ.gz format
- [ ] JSON contains expected fields
- [ ] HTML can be opened in browser
- [ ] Versions file contains fastp version
- [ ] Test completes within time limit (< 5 minutes)

## Expected Metrics (for test data)

With ~10,000 read pairs of typical quality:

- Total reads: ~20,000
- Reads passing filter: ~19,000-19,500 (95-97%)
- Bases trimmed: ~5-15% of total bases
- Adapter content: Should be low (<1%) if good quality data

## Troubleshooting

### Test fails to find input files

```
Error: Cannot find test data files
Solution: Add test data to test_data/ directory
See tests/README.md for instructions on generating test data
```

### fastp command fails

```
Check:
- Container is downloaded (run workflows/install.nf)
- Input files are valid FASTQ.gz format
- Sufficient resources in conf/test.config
```

### Output files are empty

```
Check:
- Input files contain valid data
- fastp logs for error messages
- Process log: work/<hash>/.command.log
```

## Future Improvements

- [ ] Add validation of JSON report structure
- [ ] Compare outputs against known good results
- [ ] Add test with low-quality data
- [ ] Test edge cases (empty files, single read, etc.)
- [ ] Add performance benchmarking
