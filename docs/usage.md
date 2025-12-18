# Usage Guide

Comprehensive guide for running the hybrid bacterial genome assembly pipeline.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Preparing Input Data](#preparing-input-data)
4. [Running the Pipeline](#running-the-pipeline)
5. [Assembly Modes](#assembly-modes)
6. [Configuration](#configuration)
7. [Monitoring and Resume](#monitoring-and-resume)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Nextflow** ≥ 23.04.0
- **Singularity/Apptainer** (any recent version)
- **Git** (for cloning repository)

### System Requirements

**Minimum (for testing):**
- 8 CPU cores
- 16 GB RAM
- 50 GB disk space

**Recommended (for production):**
- 16+ CPU cores
- 64+ GB RAM
- 500 GB disk space (scales with number of samples)

**HPC requirements:**
- SLURM job scheduler (or modify for your scheduler)
- Access to submit jobs
- Shared filesystem for data

## Installation

### 1. Install Nextflow

```bash
# Download and install Nextflow
curl -s https://get.nextflow.io | bash

# Make executable and move to PATH
chmod +x nextflow
sudo mv nextflow /usr/local/bin/

# Verify installation
nextflow -version
```

### 2. Clone Repository

```bash
git clone https://github.com/yourusername/listeria-hybrid-nf.git
cd listeria-hybrid-nf
```

### 3. Download Containers

**On HPC (from login node with internet access):**
```bash
nextflow run workflows/install.nf \
    --singularity_cachedir /shared/containers
```

**On local system:**
```bash
nextflow run workflows/install.nf
```

This downloads ~5-10 GB of containers. Run this once and containers are reused for all pipeline runs.

## Preparing Input Data

### Data Requirements

**For each sample, you need:**
1. **Illumina paired-end reads**
   - Forward (R1) and reverse (R2) reads
   - Gzipped FASTQ format (.fastq.gz or .fq.gz)
   - Minimum 30x coverage recommended

2. **Nanopore long reads**
   - Single FASTQ file (gzipped)
   - Minimum 50x coverage recommended
   - Quality: Q10+ (ideally Q15+)

### Creating the Samplesheet

Create a CSV file (`samplesheet.csv`) with your samples:

```csv
sample,nanopore,illumina_1,illumina_2
Sample001,/data/nanopore/sample1.fastq.gz,/data/illumina/sample1_R1.fastq.gz,/data/illumina/sample1_R2.fastq.gz
Sample002,/data/nanopore/sample2.fastq.gz,/data/illumina/sample2_R1.fastq.gz,/data/illumina/sample2_R2.fastq.gz
Sample003,/data/nanopore/sample3.fastq.gz,/data/illumina/sample3_R1.fastq.gz,/data/illumina/sample3_R2.fastq.gz
```

**Important rules:**
- ✅ Header row is required
- ✅ All four columns are required
- ✅ Use absolute paths (not relative)
- ✅ Sample names must be unique
- ❌ No spaces in sample names
- ❌ All files must exist

### Validating Your Samplesheet

```bash
# Check file exists
cat samplesheet.csv

# Verify all files exist
for file in $(tail -n +2 samplesheet.csv | cut -d',' -f2-4 | tr ',' '\n'); do
    if [ ! -f "$file" ]; then
        echo "Missing: $file"
    fi
done
```

## Running the Pipeline

### Basic Usage

**On HPC with SLURM:**
```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    -profile singularity,slurm
```

**On local workstation:**
```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --max_cpus 8 \
    --max_memory 32.GB \
    -profile singularity,local
```

### With Custom Settings

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --genome_size 3m \
    --max_cpus 16 \
    --max_memory 128.GB \
    -profile singularity,slurm \
    -resume
```

### Background Execution

**Using nohup:**
```bash
nohup nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    -profile singularity,slurm \
    > pipeline.log 2>&1 &
```

**Using screen/tmux:**
```bash
screen -S assembly
nextflow run main.nf --input samplesheet.csv -profile singularity,slurm
# Ctrl+A, D to detach
# screen -r assembly to reattach
```

## Assembly Modes

### Standard Mode (Default)

**Best for:** Most bacterial genomes

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    -profile singularity,slurm
```

**How it works:**
1. Unicycler builds assembly graph from Illumina reads
2. Nanopore reads bridge contigs and resolve repeats
3. Illumina reads polish the final assembly

**Advantages:**
- Faster (2-8 hours per sample)
- Lower memory usage
- Simpler workflow

**Typical results:**
- 10-50 contigs for bacterial genomes
- N50: 50-500 Kb

### With Flye Mode

**Best for:** Complex genomes, high-quality Nanopore data

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --use_flye \
    --genome_size 3m \
    -profile singularity,slurm
```

**How it works:**
1. Flye creates high-quality long-read assembly
2. Unicycler uses Flye assembly as scaffold
3. Illumina reads polish and correct

**Advantages:**
- Better for complex repeat structures
- Higher contiguity (larger N50)
- Often produces complete chromosomes

**Disadvantages:**
- Slower (4-12 hours per sample)
- Requires more memory
- Needs good quality Nanopore reads (Q15+)

**Typical results:**
- 1-20 contigs
- N50: 100 Kb - complete chromosome
- Often circularized chromosomes

### Choosing Assembly Mode

| Factor | Standard Mode | With Flye Mode |
|--------|---------------|----------------|
| **Genome complexity** | Simple/average | Complex repeats |
| **Nanopore quality** | Q10+ | Q15+ preferred |
| **Nanopore coverage** | 30x+ | 50x+ |
| **Time available** | Limited | Flexible |
| **Expected result** | Good assembly | Best possible assembly |

## Configuration

### Resource Limits

Control maximum resources:

```bash
nextflow run main.nf \
    --max_cpus 16 \
    --max_memory 64.GB \
    --max_time 24.h \
    ...
```

### QC Parameters

Adjust quality filtering:

```bash
nextflow run main.nf \
    --min_read_length 5000 \
    --filtlong_keep_percent 90 \
    ...
```

### Output Directory

Specify custom output location:

```bash
nextflow run main.nf \
    --outdir /path/to/results \
    ...
```

### Container Cache

Use shared container directory:

```bash
nextflow run main.nf \
    --singularity_cachedir /shared/containers \
    ...
```

## Monitoring and Resume

### Monitoring Progress

**Check running processes:**
```bash
# On SLURM
squeue -u $USER

# Check specific job
scontrol show job JOBID
```

**View log file:**
```bash
tail -f .nextflow.log
```

**Execution reports:**
Generated in `results/pipeline_info/`:
- `execution_timeline.html` - Timeline of all processes
- `execution_report.html` - Resource usage report
- `execution_trace.txt` - Detailed trace file

### Resume Failed Runs

Nextflow can resume from where it failed:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    -profile singularity,slurm \
    -resume
```

**When to use resume:**
- Job timed out
- Temporary failure (network, etc.)
- Fixed configuration error
- Added more resources

**When NOT to use resume:**
- Changed input data
- Modified process logic
- Want completely fresh run

### Clean Up

**Remove work directory:**
```bash
# After successful completion
rm -rf work/
```

**Remove specific sample:**
```bash
# Find work directories for a sample
find work/ -name "*Sample001*" -type d

# Remove them
rm -rf work/[hash]/
```

## Troubleshooting

### Pipeline Won't Start

**Issue:** Samplesheet validation fails
```
Check:
- File format is correct CSV
- All required columns present
- File paths are absolute
- All files exist
- No spaces in sample names
```

**Issue:** Container not found
```
Solution:
- Run workflows/install.nf first
- Check --singularity_cachedir path
- Verify containers downloaded correctly
```

### Process Failures

**Issue:** Out of memory
```
Solution:
- Increase --max_memory
- Check conf/base.config for process limits
- Run on nodes with more RAM
```

**Issue:** Timeout
```
Solution:
- Increase --max_time
- Use appropriate SLURM partition
- Check if process is stuck (examine logs)
```

**Issue:** Assembly fails
```
Check:
- Input data quality (coverage, read lengths)
- Nanopore read quality
- Available resources
- Process logs in work/ directory
```

### Poor Assembly Quality

**Issue:** Low completeness (<90%)
```
Check:
- Sequencing coverage (need 30-50x Illumina, 50x+ Nanopore)
- Data quality in fastp/filtlong reports
- Possible contamination

Solution:
- Increase sequencing depth
- Improve DNA quality
- Try --use_flye mode
```

**Issue:** High contamination (>5%)
```
Check:
- Sample purity
- DNA extraction quality
- FastP reports for adapter contamination

Solution:
- Re-extract DNA
- Improve laboratory protocols
- Use stricter QC parameters
```

**Issue:** Fragmented assembly (many contigs)
```
Check:
- Nanopore read length and quality
- Nanopore coverage depth

Solution:
- Increase Nanopore coverage
- Improve Nanopore read quality
- Try --use_flye mode
- Adjust --min_read_length parameter
```

### Getting Help

**Check logs:**
```bash
# Main Nextflow log
cat .nextflow.log

# Process-specific logs
cat work/[hash]/.command.log
cat work/[hash]/.command.err
```

**Examine work directory:**
```bash
# Find failed process
ls -lt work/ | head

# Check its files
ls -la work/[hash]/
cat work/[hash]/.command.sh
```

**Generate detailed report:**
```bash
nextflow log <run-name> -f script,status,duration,realtime,%cpu,%mem
```

## Best Practices

1. **Test with one sample first**
   ```bash
   # Create test samplesheet with one sample
   head -n2 samplesheet.csv > test_sample.csv
   nextflow run main.nf --input test_sample.csv ...
   ```

2. **Use -resume for long runs**
   - Saves time if run fails partway
   - Can restart after fixing issues

3. **Monitor resource usage**
   - Check execution reports
   - Adjust resources based on actual usage

4. **Keep work directory during development**
   - Enables resume functionality
   - Delete only after successful completion

5. **Use version control for configs**
   - Track configuration changes
   - Document why changes were made

6. **Regular backups**
   - Back up results directory
   - Keep execution reports

## Advanced Usage

### Running Specific Samples

Create subset samplesheet:
```bash
grep "Sample001\|Sample002" samplesheet.csv > subset.csv
nextflow run main.nf --input subset.csv ...
```

### Custom Configuration

Create custom config file:
```groovy
// custom.config
process {
    withName: 'UNICYCLER.*' {
        cpus = 24
        memory = 128.GB
    }
}
```

Use it:
```bash
nextflow run main.nf -c custom.config ...
```

### Debugging

Run with more output:
```bash
nextflow run main.nf ... -with-trace -with-report -with-timeline
```

Enable debug output:
```bash
export NXF_DEBUG=1
nextflow run main.nf ...
```

## See Also

- [Output Documentation](output.md)
- [Parameters Reference](parameters.md)
- [Configuration Files](../conf/README.md)
- [Testing Guide](../tests/README.md)
