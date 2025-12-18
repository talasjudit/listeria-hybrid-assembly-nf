# Test Data

## Purpose

This directory contains test datasets for pipeline validation and testing. Test data should be small enough to run quickly but representative enough to validate pipeline functionality.

## Required Files

For integration tests and full pipeline validation:

```
tests/data/
├── samplesheet_test.csv      # Test samplesheet
├── test_nanopore.fastq.gz    # Nanopore long reads
├── test_R1.fastq.gz          # Illumina forward reads
└── test_R2.fastq.gz          # Illumina reverse reads
```

## Test Data Requirements

### Size and Coverage

**Illumina reads:**
- ~10,000 paired reads (20,000 total reads)
- ~10-20x coverage of target genome
- Files: `test_R1.fastq.gz`, `test_R2.fastq.gz`
- Size: ~50-100 MB per file (compressed)

**Nanopore reads:**
- ~500 long reads
- ~20-30x coverage of target genome
- File: `test_nanopore.fastq.gz`
- Size: ~50-100 MB (compressed)

### Quality

Test data should be:
- **Representative:** Real bacterial genome data (or realistic synthetic data)
- **Complete:** Sufficient coverage to produce valid assembly
- **Clean:** Pre-QC'd data that will pass pipeline validation
- **Small:** Complete pipeline run in <30 minutes

### Organism

Recommended test organisms:
- **E. coli** (well-characterized, ~4.6 Mb genome)
- **Listeria monocytogenes** (target organism, ~2.9 Mb genome)
- Any well-characterized bacterial genome (2-6 Mb)

## Generating Test Data

### Option 1: Subsample Existing Data

If you have existing validated sequencing data:

```bash
# Set random seed for reproducibility
SEED=100

# Subsample Illumina reads (keep 10,000 pairs)
seqtk sample -s${SEED} original_R1.fastq.gz 10000 | gzip > test_R1.fastq.gz
seqtk sample -s${SEED} original_R2.fastq.gz 10000 | gzip > test_R2.fastq.gz

# Subsample Nanopore reads (keep 500 reads)
seqtk sample -s${SEED} original_nanopore.fastq.gz 500 | gzip > test_nanopore.fastq.gz

# Verify file sizes
ls -lh test_*.fastq.gz
```

**Tools needed:**
- [seqtk](https://github.com/lh3/seqtk): `conda install -c bioconda seqtk`

### Option 2: Download Public Data

Download and subsample from public repositories:

**SRA (Sequence Read Archive):**
```bash
# Example: Download E. coli hybrid sequencing data
# Find appropriate SRA accessions with both Illumina and Nanopore data

# Download with SRA toolkit
fastq-dump --split-files --gzip SRR_ILLUMINA_ACCESSION
fastq-dump --gzip SRR_NANOPORE_ACCESSION

# Then subsample as shown in Option 1
```

**ENA (European Nucleotide Archive):**
- Similar to SRA but often with direct FASTQ downloads

### Option 3: Simulate Synthetic Data

Generate synthetic reads (useful for CI/CD where real data isn't available):

**For Illumina (using ART):**
```bash
# Simulate Illumina reads from reference genome
art_illumina \
    -ss HS25 \
    -i reference.fasta \
    -l 150 \
    -f 20 \
    -o test_illumina \
    -p

# Rename outputs
mv test_illumina1.fq test_R1.fastq
mv test_illumina2.fq test_R2.fastq
gzip test_R1.fastq test_R2.fastq
```

**For Nanopore (using NanoSim):**
```bash
# Simulate Nanopore reads from reference
nanosim-h \
    -r reference.fasta \
    -n 500 \
    -o test_nanopore

gzip test_nanopore.fasta
mv test_nanopore.fasta.gz test_nanopore.fastq.gz
```

## Creating Test Samplesheet

Create `samplesheet_test.csv`:

```csv
sample,nanopore,illumina_1,illumina_2
test_sample,tests/data/test_nanopore.fastq.gz,tests/data/test_R1.fastq.gz,tests/data/test_R2.fastq.gz
```

**Important:**
- Use relative paths from project root
- Paths must match actual file locations
- Sample name cannot contain spaces

### Multiple Sample Samplesheet

For testing with multiple samples:

```csv
sample,nanopore,illumina_1,illumina_2
test_sample_1,tests/data/test1_nanopore.fastq.gz,tests/data/test1_R1.fastq.gz,tests/data/test1_R2.fastq.gz
test_sample_2,tests/data/test2_nanopore.fastq.gz,tests/data/test2_R1.fastq.gz,tests/data/test2_R2.fastq.gz
```

## Validating Test Data

Before using test data, verify quality:

### Check file integrity

```bash
# Verify gzip files are not corrupted
gunzip -t test_*.fastq.gz

# Check FASTQ format
zcat test_R1.fastq.gz | head -n 4
```

### Check read counts

```bash
# Count Illumina reads
echo "R1 reads: $(zcat test_R1.fastq.gz | wc -l | awk '{print $1/4}')"
echo "R2 reads: $(zcat test_R2.fastq.gz | wc -l | awk '{print $1/4}')"

# Count Nanopore reads
echo "Nanopore reads: $(zcat test_nanopore.fastq.gz | wc -l | awk '{print $1/4}')"
```

### Estimate coverage

```bash
# Rough coverage estimate
GENOME_SIZE=3000000  # 3 Mb for Listeria

# Illumina coverage
ILLUMINA_BASES=$(zcat test_R1.fastq.gz test_R2.fastq.gz | paste - - - - | cut -f2 | tr -d '\n' | wc -c)
ILLUMINA_COV=$(echo "$ILLUMINA_BASES / $GENOME_SIZE" | bc)
echo "Illumina coverage: ${ILLUMINA_COV}x"

# Nanopore coverage (similar calculation)
```

## Storage Considerations

### Git LFS (Large File Storage)

If committing test data to git:

```bash
# Install git-lfs
git lfs install

# Track test data files
git lfs track "tests/data/*.fastq.gz"

# Commit .gitattributes
git add .gitattributes
git commit -m "Track test data with Git LFS"

# Add and commit test data
git add tests/data/*.fastq.gz
git commit -m "Add test data"
```

### Alternative: External Storage

For larger test datasets, consider:
- Hosting on Zenodo or FigShare (with DOI)
- Cloud storage (S3, Google Cloud Storage)
- Institutional storage
- Download script to fetch data when needed

Example download script (`tests/data/download_test_data.sh`):
```bash
#!/bin/bash
# Download test data from external source

wget https://example.com/test_data/test_R1.fastq.gz
wget https://example.com/test_data/test_R2.fastq.gz
wget https://example.com/test_data/test_nanopore.fastq.gz

echo "Test data downloaded successfully"
```

## Expected Test Results

With properly generated test data:

### Assembly Metrics
- Completeness (CheckM2): >80%
- Contamination (CheckM2): <5%
- N50 (QUAST): >10 Kb
- Number of contigs: <100
- Total assembly size: Within 20% of expected genome size

### Runtime
- Total pipeline runtime: <30 minutes
- Individual process times:
  - fastp: ~2-3 min
  - Porechop + Filtlong: ~3-5 min
  - Unicycler: ~10-15 min
  - CheckM2 + QUAST: ~5-8 min

### Resource Usage
- Peak memory: ~6 GB
- Peak CPU: 2 cores
- Disk space: ~2 GB (work + output)

## Troubleshooting

### Test data too small
```
Symptom: Assembly fails or has very low quality
Solution: Increase coverage by subsampling more reads
```

### Test data too large
```
Symptom: Tests take too long (>30 min) or run out of resources
Solution: Reduce number of reads in subsampling
```

### Poor assembly quality
```
Symptom: Low completeness, high contamination, or fragmented assembly
Solution:
- Check input data quality with FastQC
- Ensure sufficient coverage (>20x for both Illumina and Nanopore)
- Use higher quality source data for subsampling
```

## Maintenance

### Updating Test Data

When updating test data:
1. Document why change is needed
2. Re-run full integration tests
3. Update baseline results if needed
4. Update this README with new expectations
5. Commit changes with clear message

### Versioning

Consider versioning test data:
```
tests/data/
├── v1.0/
│   ├── test_R1.fastq.gz
│   └── ...
└── v2.0/
    ├── test_R1.fastq.gz
    └── ...
```

This allows testing against different datasets and maintaining backwards compatibility.

## TODO

- [ ] Add actual test data files
- [ ] Create download script for external test data
- [ ] Document expected baseline results
- [ ] Add multiple test datasets (easy, medium, hard)
- [ ] Create validation script to check test data quality
- [ ] Set up Git LFS or external storage
- [ ] Add checksums (MD5/SHA256) for data integrity verification
