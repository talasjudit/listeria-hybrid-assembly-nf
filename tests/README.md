# Testing Documentation

## Overview

This directory contains unit tests for individual modules and integration tests for the full pipeline. A comprehensive testing strategy ensures the pipeline works correctly and helps catch regressions during development.

## Directory Structure

```
tests/
├── README.md               # This file
├── modules/                # Unit tests for each process
│   ├── fastp/
│   ├── porechop_abi/
│   ├── filtlong/
│   ├── flye/
│   ├── unicycler/
│   ├── unicycler_with_flye/
│   ├── checkm2/
│   ├── quast/
│   └── multiqc/
├── integration/            # Full pipeline integration tests
│   └── test_full_pipeline.nf
└── data/                   # Test data (to be added)
    ├── samplesheet_test.csv
    └── README.md
```

## Testing Strategy

### 1. Unit Tests (Module Level)

Each process module has its own test workflow that:
- Runs the module in isolation
- Uses small test datasets
- Verifies expected outputs are created
- Checks output files are valid and non-empty

**When to run:** During module development and after modifications

### 2. Integration Tests (Full Pipeline)

Integration tests run the entire pipeline to ensure:
- All modules work together correctly
- Data flows between processes as expected
- Final outputs meet quality thresholds
- Pipeline completes without errors

**When to run:** Before merging changes, before releases

### 3. Stub Tests

Nextflow's stub feature allows testing workflow logic without running actual commands:
- Fast execution (seconds instead of hours)
- Tests channel operations and workflow structure
- Useful for CI/CD pipelines

**When to run:** During workflow development, in CI/CD

## Running Tests

### Prerequisites

```bash
# 1. Install containers (if not already done)
nextflow run workflows/install.nf --singularity_cachedir ./singularity_cache

# 2. Ensure you have test data (see tests/data/README.md)
```

### Unit Tests

Test a specific module:

```bash
# Test fastp module
cd tests/modules/fastp
nextflow run test_fastp.nf -profile test,singularity

# Or from project root
nextflow run tests/modules/fastp/test_fastp.nf -profile test,singularity
```

Test all modules:

```bash
# Create a test runner script
./run_all_module_tests.sh
```

### Integration Tests

Run full pipeline with test data:

```bash
nextflow run tests/integration/test_full_pipeline.nf -profile test,singularity
```

Or use the test config directly with main pipeline:

```bash
nextflow run main.nf -profile test,singularity
```

### Stub Tests

Test workflow structure without executing processes:

```bash
nextflow run main.nf -profile test -stub-run
```

## Test Data

### Requirements

Test data should be:
- **Small:** Complete in <30 minutes
- **Representative:** Real bacterial genome data (or realistic synthetic)
- **Complete:** Include both Illumina and Nanopore reads
- **Valid:** Should produce valid assemblies

### Recommended Test Data

For a bacterial genome (e.g., E. coli or Listeria):

**Illumina reads:**
- ~10,000 paired reads (20,000 total)
- ~10-20x coverage
- Files: `test_R1.fastq.gz`, `test_R2.fastq.gz`

**Nanopore reads:**
- ~500 long reads
- ~20-30x coverage
- File: `test_nanopore.fastq.gz`

### Generating Test Data

If you have existing validated data:

```bash
# Subsample Illumina reads (keep 10,000 pairs)
seqtk sample -s100 full_R1.fastq.gz 10000 | gzip > test_R1.fastq.gz
seqtk sample -s100 full_R2.fastq.gz 10000 | gzip > test_R2.fastq.gz

# Subsample Nanopore reads (keep 500 reads)
seqtk sample -s100 full_nanopore.fastq.gz 500 | gzip > test_nanopore.fastq.gz
```

### Test Samplesheet

Create `tests/data/samplesheet_test.csv`:

```csv
sample,nanopore,illumina_1,illumina_2
test_sample,tests/data/test_nanopore.fastq.gz,tests/data/test_R1.fastq.gz,tests/data/test_R2.fastq.gz
```

## Expected Test Results

### Successful Test Run

A successful test should:
- Complete all processes without errors
- Produce all expected output files
- Generate valid assembly (FASTA format, non-empty)
- Complete within resource limits (time, memory)

### Quality Thresholds for Test Data

Since test data is small, quality metrics will be lower than production:

**CheckM2 (expected for test data):**
- Completeness: >80% (lower than production due to low coverage)
- Contamination: <5%

**QUAST (expected for test data):**
- Number of contigs: <100
- N50: >10 Kb (lower than production)
- Total length: Within 20% of expected genome size

## Debugging Failed Tests

### Common Issues

**1. Container not found**
```
Solution: Run workflows/install.nf to download containers
```

**2. Test data not found**
```
Solution: Check paths in samplesheet, ensure files exist
```

**3. Process out of memory**
```
Solution: Check conf/test.config resources, may need to increase
```

**4. Assembly fails**
```
Solution: Test data may be too small/poor quality, try increasing coverage
```

### Debugging Steps

1. **Check work directory:**
   ```bash
   ls -la work/
   ```

2. **Examine process logs:**
   ```bash
   cat work/<hash>/.command.log
   cat work/<hash>/.command.err
   ```

3. **View process script:**
   ```bash
   cat work/<hash>/.command.sh
   ```

4. **Use -resume to continue:**
   ```bash
   nextflow run test_fastp.nf -profile test,singularity -resume
   ```

5. **Increase verbosity:**
   ```bash
   nextflow run test_fastp.nf -profile test,singularity -with-trace -with-report
   ```

## Continuous Integration (CI/CD)

### GitHub Actions

Example workflow for automated testing:

```yaml
name: Pipeline Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install Nextflow
        run: |
          wget -qO- https://get.nextflow.io | bash
          chmod +x nextflow
          sudo mv nextflow /usr/local/bin/

      - name: Install Singularity
        run: |
          # Install Singularity commands here

      - name: Download containers
        run: nextflow run workflows/install.nf

      - name: Run tests
        run: |
          nextflow run main.nf -profile test -stub-run
          # Add actual tests once test data is available
```

## Test Development Checklist

When adding a new module, create tests that verify:

- [ ] Module can be imported and executed
- [ ] All expected outputs are produced
- [ ] Output files are non-empty
- [ ] Output files have correct format
- [ ] Process completes within resource limits
- [ ] Version capture works correctly
- [ ] Stub mode works correctly

## Best Practices

1. **Keep tests fast:** Use minimal data, aim for <5 min per module test
2. **Test edge cases:** Empty files, single sample, multiple samples
3. **Verify outputs:** Don't just check files exist, verify they're valid
4. **Use stub mode:** Test workflow logic without running actual processes
5. **Document test data:** Clearly document what test data represents
6. **Automate testing:** Set up CI/CD for automatic testing on changes
7. **Test cleanup:** Remove intermediate files to save disk space

## TODO for Phase 2+

- [x] Add actual test data to `tests/data/`
- [x] Implement most module test workflows
- [x] Create integration test workflow (subworkflows tested)
- [ ] Create main pipeline integration test
- [ ] Set up CI/CD pipeline
- [ ] Add test data generation scripts
- [ ] Document expected test outputs
- [ ] Create test runner script for all module tests
- [ ] Add performance benchmarks for tests

## Resources

- [Nextflow Testing Documentation](https://www.nextflow.io/docs/latest/testing.html)
- [nf-core Testing Guidelines](https://nf-co.re/docs/contributing/modules#writing-tests)
- [Nextflow Patterns](https://nextflow-io.github.io/patterns/)
