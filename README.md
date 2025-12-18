# Hybrid Bacterial Genome Assembly Pipeline

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg)](https://sylabs.io/docs/)

A Nextflow pipeline for hybrid assembly of bacterial genomes using Illumina short reads and Oxford Nanopore long reads.

## Overview

This pipeline combines the high accuracy of Illumina short reads with the long-range information from Nanopore sequencing to produce high-quality bacterial genome assemblies. It's designed for bacterial genomes (2-6 Mb) with emphasis on Listeria species, but is applicable to any bacterial genome.

### Pipeline Workflow

```
Illumina reads → fastp (QC + trimming)
                      ↓
Nanopore reads → porechop_abi (adapter removal) → filtlong (quality filtering)
                      ↓
                [Optional: Flye long-read assembly]
                      ↓
              Unicycler (hybrid assembly)
                      ↓
      CheckM2 (completeness) + QUAST (statistics)
                      ↓
            MultiQC (aggregated report)
```

### Key Features

- **Hybrid assembly:** Combines Illumina accuracy with Nanopore contiguity
- **Two assembly modes:** Standard Unicycler or Unicycler with Flye scaffold
- **Comprehensive QC:** Quality control at every step
- **Flexible execution:** HPC (SLURM) or local workstation
- **Container-based:** All tools in Singularity containers
- **Well-documented:** Extensive documentation and comments
- **Resumable:** Built-in resume capability for failed runs

## Quick Start

### 1. Prerequisites

- **Nextflow** ≥ 23.04.0
- **Singularity/Apptainer** (for containers)
- **Git** (for cloning repository)

```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# Verify Singularity is installed
singularity --version
```

### 2. Clone Repository

```bash
git clone https://github.com/yourusername/listeria-hybrid-nf.git
cd listeria-hybrid-nf
```

### 3. Download Containers

```bash
# Download all required Singularity containers
nextflow run main.nf -entry INSTALL -profile singularity

# This downloads ~5-10 GB of containers
# Run on a node with internet access
```

### 4. Prepare Samplesheet

Create a CSV file with your samples:

```csv
sample,nanopore,illumina_1,illumina_2
Sample001,/data/nanopore/sample1.fastq.gz,/data/illumina/sample1_R1.fastq.gz,/data/illumina/sample1_R2.fastq.gz
Sample002,/data/nanopore/sample2.fastq.gz,/data/illumina/sample2_R1.fastq.gz,/data/illumina/sample2_R2.fastq.gz
```

**Requirements:**
- All paths must be absolute
- All samples must have BOTH Illumina AND Nanopore data
- Sample names cannot contain spaces
- Files must be gzipped FASTQ format

### 5. Run Pipeline

**On QIB/NBI HPC:**
```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  -profile qib
```

> #### HPC Without Internet Access
> If your HPC login/submission nodes don't have internet access, 
> you'll need to set these environment variables:
> ```bash
> export NXF_OFFLINE=true
> export NXF_DISABLE_REMOTE_LOGS=true
> ```

**On local workstation:**
```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --max_cpus 8 \
  --max_memory 32.GB \
  -profile local
```

**With Flye pre-assembly (for complex genomes):**
```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --use_flye \
  -profile qib
```

## Pipeline Steps

### 1. Input Validation
- Parse and validate samplesheet
- Check file existence and format
- Validate sample names

### 2. Illumina QC (fastp)
- Adapter detection and removal
- Quality filtering
- Base correction for overlapping pairs
- Generate QC reports

### 3. Nanopore QC
- **Porechop ABI:** Remove sequencing adapters
- **Filtlong:** Filter by quality and length
- Keep top 95% of reads (default)

### 4. Assembly
**Standard mode (default):**
- Unicycler builds graph from Illumina reads
- Uses Nanopore reads to bridge contigs

**With Flye mode (`--use_flye`):**
- Flye creates long-read assembly first
- Unicycler uses Flye assembly as scaffold
- Illumina reads polish and correct

### 5. Assembly QC
- **CheckM2:** Completeness and contamination
- **QUAST:** Assembly statistics (N50, contigs, etc.)

### 6. Reporting
- **MultiQC:** Aggregated HTML report

## Output Structure

```
results/
├── fastp/              # Trimmed Illumina reads and QC reports
├── porechop/           # Adapter-trimmed Nanopore reads
├── filtlong/           # Quality-filtered Nanopore reads
├── flye/               # Flye assemblies (if --use_flye)
├── unicycler/          # Final hybrid assemblies ← MAIN OUTPUT
├── checkm2/            # Completeness reports
├── quast/              # Assembly statistics
├── multiqc/            # Aggregated QC report
│   └── multiqc_report.html  ← START HERE
└── pipeline_info/      # Execution reports
    ├── execution_timeline.html
    ├── execution_report.html
    └── execution_trace.txt
```

## Documentation

- **[Usage Guide](docs/usage.md)** - Detailed usage instructions
- **[Output Description](docs/output.md)** - Understanding pipeline outputs
- **[Parameters](docs/parameters.md)** - All configurable parameters
- **[Testing](tests/README.md)** - Testing and validation

## Configuration

### Profiles

| Profile | Purpose |
|---------|---------|
| `qib` | QIB/NBI HPC with SLURM (partition auto-selection) |
| `slurm` | Generic SLURM HPC (customize partitions) |
| `local` | Local workstation execution |
| `test` | Test resources (combine with executor profile) |

> **Note:** Singularity is auto-enabled in all profiles. No need to specify `-profile singularity` separately.

**Common usage:**
```bash
-profile test,qib      # QIB HPC testing
-profile qib           # QIB HPC production
-profile test,local    # Local testing
-profile slurm         # Generic SLURM (customize partitions)
```

### Common Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | null | **Required:** Path to samplesheet CSV |
| `--outdir` | results | Output directory |
| `--use_flye` | false | Run Flye before Unicycler |
| `--genome_size` | 3m | Expected genome size for Flye |
| `--max_cpus` | 12 | Maximum CPUs per process |
| `--max_memory` | 128.GB | Maximum memory per process |
| `--max_time` | 24.h | Maximum time per process |

See [docs/parameters.md](docs/parameters.md) for complete list.

### Resource Configuration

Modify resource allocations in:
- `conf/base.config` - Per-process resources
- `conf/slurm.config` - SLURM-specific settings
- `conf/local.config` - Local execution settings

## Assembly Modes

### Standard Mode (default)

Best for: Most bacterial genomes

```bash
nextflow run main.nf --input samplesheet.csv -profile singularity,slurm
```

**Advantages:**
- Faster execution (2-8 hours per sample)
- Lower memory usage (16-32 GB)
- Simpler workflow

### With Flye Mode

Best for: Complex genomes with repeats, when Unicycler alone struggles

```bash
nextflow run main.nf --input samplesheet.csv --use_flye -profile singularity,slurm
```

**Advantages:**
- Better for complex repeat structures
- Higher contiguity (larger N50)
- Better repeat resolution
- Often results in complete chromosomes

**Disadvantages:**
- Slower (4-12 hours per sample)
- Higher memory usage (32-64 GB)
- Requires good quality Nanopore reads

## Quality Metrics

### Expected Results for Good Assembly

**CheckM2:**
- Completeness: >95%
- Contamination: <2%

**QUAST:**
- Number of contigs: <50 for bacterial genome
- N50: >100 Kb (often >1 Mb for good hybrid assembly)
- Total length: Should match expected genome size (±5%)

**For Listeria monocytogenes:**
- Expected size: ~2.9-3.0 Mb
- Expected contigs: 1-20 (often complete in 1-5 contigs with good data)

## Troubleshooting

### Pipeline fails to start
```
Check:
- Samplesheet format is correct
- All input files exist
- Paths are absolute
- Singularity containers are downloaded
```

### Process out of memory
```
Solution:
- Increase max_memory parameter
- Check conf/base.config for process-specific limits
- Use SLURM profile for better resource management
```

### Low assembly quality
```
Check:
- Input data coverage (need 30-50x Illumina, 50x+ Nanopore)
- FastP and Filtlong QC reports
- Consider using --use_flye mode
- Check for contamination in input data
```

### Assembly is fragmented (many contigs)
```
Solutions:
- Check Nanopore read quality and length
- Increase Nanopore coverage
- Try --use_flye mode
- Adjust --min_read_length parameter
```

For more troubleshooting, see [docs/usage.md](docs/usage.md).

## Development Status

🚧 **Current Status: Phase 3 - Workflow Integration & Testing**

### Phase 1 ✅ (Complete)
- [x] Project structure and directory organization
- [x] Configuration files (Nextflow, profiles, resources)
- [x] Validation schemas (parameters and samplesheet)
- [x] All process module templates
- [x] Subworkflow templates
- [x] Main workflow template
- [x] Testing framework structure
- [x] Documentation
- [x] Working installation workflow

### Phase 2 ✅ (Complete)
- [x] Implement process modules (fastp, porechop, filtlong, unicycler, checkm2, quast)
- [x] Implement subworkflows (QC sequences, Assembly, QC assembly)
- [x] Local module testing
- [x] Container verification

### Phase 3 ⏳ (In Progress)
- [x] Input validation subworkflow (nf-schema)
- [ ] Connect workflow steps in main.nf
- [ ] Integration testing with real data
- [ ] Parameter optimization
- [ ] Performance tuning
- [ ] Release v1.0.0

## Tools and Versions

| Tool | Version | Purpose |
|------|---------|---------|
| fastp | 1.0.1 | Illumina QC |
| porechop_abi | 0.5.0 | Nanopore adapter removal |
| filtlong | 0.3.0 | Nanopore quality filtering |
| Flye | 2.9.6 | Long-read assembly |
| Unicycler | 0.5.1 | Hybrid assembly |
| CheckM2 | 1.1.0 | Completeness assessment |
| QUAST | 5.3.0 | Assembly statistics |
| MultiQC | 1.31 | Report aggregation |

All tools run in Singularity containers from GHCR and Quay.io.

## Citation

If you use this pipeline in your research, please cite:

**Pipeline:**
```
TODO: Add citation after publication
```

**Key tools:**
- **Unicycler:** Wick RR, et al. (2017) PLoS Comput Biol 13(6): e1005595
- **Flye:** Kolmogorov M, et al. (2019) Nat Biotechnol 37: 540-546
- **CheckM2:** Chklovski A, et al. (2023) Nat Methods 20: 1203-1212
- **QUAST:** Gurevich A, et al. (2013) Bioinformatics 29(8): 1072-1075

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

See issues page for current development priorities.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions, issues, or suggestions:
- **Issues:** https://github.com/yourusername/listeria-hybrid-nf/issues
- **Email:** your.email@institution.edu

## Acknowledgments

- Pipeline development assisted by AI pair programming
- Container images hosted on GitHub Container Registry
- Pipeline structure inspired by nf-core best practices
- Developed for bacterial genomics research

---

**Repository:** https://github.com/yourusername/listeria-hybrid-nf
**Documentation:** https://github.com/yourusername/listeria-hybrid-nf/docs
**Version:** 1.0.0dev
