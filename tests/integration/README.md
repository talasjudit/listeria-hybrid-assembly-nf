# Integration Tests

## Purpose

Integration tests verify that the complete pipeline works correctly from end to end, including:
- All processes execute successfully
- Data flows correctly between processes
- Final outputs meet quality thresholds
- Pipeline completes within resource limits

## Running Integration Tests

### Recommended Approach

Use the main pipeline with the test profile:

```bash
nextflow run main.nf -profile test,singularity
```

This approach:
- Tests the actual production workflow
- No need to maintain separate test workflow
- Ensures what you test is what you run

### Alternative: Dedicated Test Workflow

Use the dedicated integration test workflow:

```bash
nextflow run tests/integration/test_full_pipeline.nf -profile test,singularity
```

This workflow can be extended to include:
- Additional validation steps
- Output file verification
- Quality threshold checking
- Comparison against known good results

## Test Data Requirements

Integration tests require complete test dataset:

```
tests/data/
├── samplesheet_test.csv      # Test samplesheet
├── test_nanopore.fastq.gz    # Nanopore reads (~500 reads)
├── test_R1.fastq.gz          # Illumina R1 (~10,000 reads)
└── test_R2.fastq.gz          # Illumina R2 (~10,000 reads)
```

See `tests/data/README.md` for instructions on generating test data.

## Expected Behavior

### Timeline

With test data on moderate hardware:
- Input validation: <1 min
- fastp (Illumina QC): ~2-3 min
- Porechop + Filtlong (Nanopore QC): ~3-5 min
- Unicycler (assembly): ~10-15 min
- CheckM2 + QUAST (QC): ~5-8 min
- MultiQC: <1 min
- **Total: ~20-30 minutes**

### Resource Usage

Expected peak resource usage:
- CPU: 2 cores (as configured in test.config)
- Memory: ~6 GB
- Disk: ~2 GB (work directory + outputs)

### Output Structure

```
tests/results/
├── fastp/
│   ├── test_sample_R1_trimmed.fastq.gz
│   ├── test_sample_R2_trimmed.fastq.gz
│   ├── test_sample.json
│   └── test_sample.html
├── porechop/
│   ├── test_sample_porechop.fastq.gz
│   └── test_sample.log
├── filtlong/
│   ├── test_sample_filtlong.fastq.gz
│   └── test_sample.log
├── unicycler/
│   ├── test_sample_unicycler.fasta
│   └── test_sample.log
├── checkm2/
│   └── test_sample_checkm2/
│       └── quality_report.tsv
├── quast/
│   └── test_sample_quast/
│       ├── report.tsv
│       └── report.html
├── multiqc/
│   ├── multiqc_report.html
│   └── multiqc_data/
└── pipeline_info/
    ├── execution_timeline.html
    ├── execution_report.html
    └── execution_trace.txt
```

## Validation Checklist

After integration test completes, verify:

### Output Files
- [ ] All expected output directories exist
- [ ] Assembly file is non-empty and valid FASTA format
- [ ] MultiQC report can be opened in browser
- [ ] All expected files are present (no missing outputs)

### Assembly Quality (for test data)
- [ ] CheckM2 completeness >80%
- [ ] CheckM2 contamination <5%
- [ ] QUAST N50 >10 Kb
- [ ] QUAST number of contigs <100
- [ ] Assembly size within 20% of expected genome size

### Execution
- [ ] No process failures
- [ ] Total runtime <30 minutes
- [ ] Peak memory usage <6 GB
- [ ] No error messages in logs

### Reports
- [ ] MultiQC report shows data from all tools
- [ ] Execution timeline shows expected process flow
- [ ] No warnings about missing files

## Quality Thresholds

### Test Data Expectations

Because test data has lower coverage than production data, quality metrics will be lower:

| Metric | Test Data Target | Production Target |
|--------|------------------|-------------------|
| CheckM2 Completeness | >80% | >95% |
| CheckM2 Contamination | <5% | <2% |
| QUAST N50 | >10 Kb | >100 Kb |
| QUAST Contigs | <100 | <50 |
| Assembly Size | ±20% expected | ±5% expected |

### Interpreting Results

**Excellent test result:**
- Completeness >90%
- Contamination <2%
- N50 >50 Kb
- <50 contigs

**Acceptable test result:**
- Completeness >80%
- Contamination <5%
- N50 >10 Kb
- <100 contigs

**Problematic test result:**
- Completeness <80%
- Contamination >5%
- N50 <10 Kb
- >100 contigs

If results are problematic, check:
- Test data quality (may need better test dataset)
- Resource limitations (increase in test.config)
- Process logs for errors or warnings

## Comparing Results

### Baseline Results

Once you have known-good test results, save them as baseline:

```bash
# Run test and save results
nextflow run main.nf -profile test,singularity
cp tests/results/checkm2/*/quality_report.tsv tests/baseline/checkm2_baseline.tsv
cp tests/results/quast/*/report.tsv tests/baseline/quast_baseline.tsv
```

### Regression Testing

Compare new results against baseline:

```bash
# After making changes, run test again
nextflow run main.nf -profile test,singularity -resume

# Compare results
diff tests/baseline/quast_baseline.tsv tests/results/quast/*/report.tsv
```

Significant differences may indicate:
- Regression (worse results)
- Improvement (better results)
- Changed behavior requiring investigation

## Troubleshooting

### Test times out
```
Issue: Pipeline exceeds time limit
Solution:
- Increase max_time in conf/test.config
- Check if process is stuck (examine logs)
- Verify test data size is appropriate
```

### Out of memory
```
Issue: Process killed due to memory limit
Solution:
- Increase max_memory in conf/test.config
- Check process logs for memory-intensive step
- Verify test data isn't too large
```

### Assembly quality too low
```
Issue: CheckM2 completeness <80%
Solution:
- Check input data quality
- Increase test data coverage
- Review fastp and filtlong outputs
- May indicate problem with assembly process
```

### Missing outputs
```
Issue: Expected files not created
Solution:
- Check process logs in work/ directory
- Review execution trace for failed processes
- Verify all containers are downloaded
- Check for permission issues
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Integration Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Nextflow
        run: |
          wget -qO- https://get.nextflow.io | bash
          sudo mv nextflow /usr/local/bin/

      - name: Setup Singularity
        run: |
          # Install Singularity

      - name: Download containers
        run: nextflow run workflows/install.nf

      - name: Run integration test
        run: nextflow run main.nf -profile test,singularity

      - name: Validate outputs
        run: |
          # Add validation scripts
          test -f tests/results/multiqc/multiqc_report.html
          test -f tests/results/unicycler/*/assembly.fasta
```

## Future Improvements

- [ ] Automated validation of output file formats
- [ ] Comparison against known-good baseline results
- [ ] Performance benchmarking and tracking
- [ ] Multiple test datasets (easy, medium, challenging)
- [ ] Automated quality threshold checking
- [ ] Test data hosted remotely (no need to commit large files)
- [ ] Parameterized tests (test different parameter combinations)
