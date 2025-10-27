# Parameters Reference

Complete reference for all pipeline parameters.

## Table of Contents

1. [Required Parameters](#required-parameters)
2. [Input/Output Options](#inputoutput-options)
3. [Assembly Options](#assembly-options)
4. [QC Options](#qc-options)
5. [Resource Options](#resource-options)
6. [Container Options](#container-options)
7. [MultiQC Options](#multiqc-options)
8. [Generic Options](#generic-options)

## Parameter Overview

| Category | Required | Optional |
|----------|----------|----------|
| Input/Output | `--input`, `--outdir` | `--tracedir` |
| Assembly | - | `--use_flye`, `--genome_size` |
| QC | - | `--min_coverage`, `--min_read_length`, etc. |
| Resources | - | `--max_cpus`, `--max_memory`, `--max_time` |

## Required Parameters

### --input

**Type:** String (file path)
**Required:** Yes
**Description:** Path to samplesheet CSV file

**Example:**
```bash
--input samplesheet.csv
--input /path/to/samples.csv
```

**Validation:**
- File must exist
- Must be valid CSV format
- Must contain required columns: `sample`, `nanopore`, `illumina_1`, `illumina_2`
- All file paths in samplesheet must exist

**See Also:** [Samplesheet format documentation](usage.md#preparing-input-data)

## Input/Output Options

### --outdir

**Type:** String (directory path)
**Default:** `results`
**Description:** Output directory for results

**Example:**
```bash
--outdir results
--outdir /scratch/$USER/assembly_results
```

**Notes:**
- Directory will be created if it doesn't exist
- Use absolute path for cluster jobs
- Ensure sufficient disk space

### --tracedir

**Type:** String (directory path)
**Default:** `${params.outdir}/pipeline_info`
**Description:** Directory for Nextflow execution reports

**Example:**
```bash
--tracedir ${params.outdir}/logs
```

**Generated files:**
- `execution_timeline.html`
- `execution_report.html`
- `execution_trace.txt`
- `pipeline_dag.svg`

## Assembly Options

### --use_flye

**Type:** Boolean
**Default:** `false`
**Description:** Run Flye long-read assembly before Unicycler

**Example:**
```bash
# Enable Flye mode
--use_flye

# Or explicitly
--use_flye true

# Disable (default)
--use_flye false
```

**When to use:**
- Complex genomes with repeats
- High-quality Nanopore data (Q15+)
- Want maximum contiguity
- Have computational resources (time and memory)

**When NOT to use:**
- Standard bacterial genomes
- Limited computational resources
- Lower quality Nanopore data
- Fast turnaround needed

**See Also:** [Assembly modes](usage.md#assembly-modes)

### --genome_size

**Type:** String
**Default:** `3m`
**Description:** Expected genome size for Flye assembly

**Format:**
- Number followed by unit: `k` (kilobases), `m` (megabases), `g` (gigabases)
- Examples: `3m`, `4.5m`, `3000k`, `0.003g`

**Example:**
```bash
# For E. coli (~4.6 Mb)
--genome_size 4.6m

# For Listeria (~3 Mb)
--genome_size 3m

# Alternative formats
--genome_size 3000k
```

**Important:**
- Only used if `--use_flye` is enabled
- Should be approximate expected size
- Too far off can affect assembly quality

**Typical bacterial genome sizes:**
- Small bacteria: 1-2 Mb
- Average bacteria: 3-5 Mb
- Large bacteria: 6-10 Mb

## QC Options

### --min_coverage

**Type:** Integer
**Default:** `30`
**Description:** Minimum Illumina coverage threshold (warning only)

**Example:**
```bash
--min_coverage 30
--min_coverage 50  # Stricter
```

**Notes:**
- Generates warning if coverage is below threshold
- Pipeline continues even if below threshold
- Used for quality assessment, not filtering

### --max_coverage

**Type:** Integer
**Default:** `40`
**Description:** Target maximum Illumina coverage (for potential downsampling)

**Example:**
```bash
--max_coverage 40
--max_coverage 100  # For high coverage samples
```

**Notes:**
- Currently generates warnings for high coverage
- Future versions may implement downsampling

### --min_read_length

**Type:** Integer
**Default:** `6000`
**Description:** Minimum Nanopore read length for Filtlong filtering (base pairs)

**Example:**
```bash
--min_read_length 6000   # Default
--min_read_length 5000   # More permissive
--min_read_length 8000   # Stricter
```

**Considerations:**
- Lower value: Keep more reads, but lower quality
- Higher value: Higher quality, but fewer reads
- Typical Nanopore read lengths: 5-50 Kb
- Consider your sequencing platform and quality

**Recommendations:**
- Standard run: 6000 bp
- High-quality data: 8000 bp
- Lower quality data: 5000 bp
- Very high quality: 10000 bp

### --filtlong_keep_percent

**Type:** Integer
**Default:** `95`
**Range:** 1-100
**Description:** Percentage of best quality reads to keep in Filtlong

**Example:**
```bash
--filtlong_keep_percent 95   # Default - keep top 95%
--filtlong_keep_percent 90   # More aggressive filtering
--filtlong_keep_percent 98   # Less aggressive filtering
```

**How it works:**
- Filtlong ranks all reads by quality
- Keeps the top N% of reads
- Discards the lowest quality reads

**Choosing a value:**
- 95-98%: Standard, recommended for most cases
- 90-95%: More aggressive, for very high coverage or lower quality
- 98-100%: Less aggressive, for lower coverage or high quality

**Impact:**
- Lower %: Fewer but higher quality reads → Better assembly accuracy
- Higher %: More reads but lower average quality → Better coverage

## Resource Options

### --max_cpus

**Type:** Integer
**Default:** `12`
**Description:** Maximum number of CPUs any single process can request

**Example:**
```bash
--max_cpus 12    # Default
--max_cpus 8     # For smaller systems
--max_cpus 24    # For larger systems
```

**Notes:**
- Individual processes request CPUs based on their needs
- This parameter caps the maximum
- Actual usage depends on process requirements (see `conf/base.config`)

**Recommendations:**
- Local workstation: Set to physical cores - 2
- HPC node: Set to node's CPU count
- Shared system: Set to fair share allocation

### --max_memory

**Type:** String (with unit)
**Default:** `128.GB`
**Description:** Maximum memory any single process can request

**Example:**
```bash
--max_memory 128.GB   # Default
--max_memory 64.GB    # For smaller systems
--max_memory 256.GB   # For larger systems
```

**Format:**
- Number + unit: `KB`, `MB`, `GB`, `TB`
- Examples: `32.GB`, `64GB`, `128.GB`

**Notes:**
- Processes request memory based on their needs
- This parameter caps the maximum
- Ensure your system has this much RAM available

**Memory-intensive processes:**
- Unicycler: 16-32 GB typical
- Flye: 32-64 GB typical
- CheckM2: 8-16 GB typical

**Recommendations:**
- Small workstation (16 GB RAM): `--max_memory 12.GB`
- Medium workstation (32 GB RAM): `--max_memory 24.GB`
- Large workstation (64 GB RAM): `--max_memory 48.GB`
- HPC node (128+ GB RAM): `--max_memory 128.GB` or higher

### --max_time

**Type:** String (with unit)
**Default:** `24.h`
**Description:** Maximum time any single process can request

**Example:**
```bash
--max_time 24.h    # Default
--max_time 12.h    # For faster queues
--max_time 48.h    # For long queues
```

**Format:**
- Number + unit: `s` (seconds), `m` (minutes), `h` (hours), `d` (days)
- Examples: `4.h`, `24.h`, `1.d`, `30.m`

**Time-intensive processes:**
- Unicycler: 2-8 hours typical
- Flye: 4-12 hours typical
- Other processes: <2 hours

**Recommendations:**
- Fast queue (short partition): `--max_time 4.h`
- Standard queue: `--max_time 24.h`
- Long queue: `--max_time 48.h`

## Container Options

### --singularity_cachedir

**Type:** String (directory path)
**Default:** `./singularity_cache`
**Description:** Directory where Singularity containers are stored

**Example:**
```bash
--singularity_cachedir ./singularity_cache
--singularity_cachedir /shared/containers
--singularity_cachedir $HOME/containers
```

**Best practices:**
- Use shared directory on HPC (avoid duplicate downloads)
- Ensure sufficient disk space (~5-10 GB)
- Use fast storage if possible
- Check permissions (must be readable by all users)

**On HPC:**
```bash
# Shared location
--singularity_cachedir /shared/singularity

# User-specific location
--singularity_cachedir $HOME/.singularity
```

### --singularity_pull_docker_container

**Type:** Boolean
**Default:** `false`
**Description:** Convert Docker containers to Singularity instead of pulling native Singularity images

**Example:**
```bash
--singularity_pull_docker_container true
```

**Notes:**
- Usually not needed (pipeline uses native Singularity images)
- May be required if Singularity images are unavailable
- Requires Docker daemon access

## MultiQC Options

### --multiqc_title

**Type:** String
**Default:** `Hybrid Assembly Report`
**Description:** Title for the MultiQC report

**Example:**
```bash
--multiqc_title "My Project - Assembly QC"
--multiqc_title "Listeria Assembly - Batch 5"
```

**Usage:**
- Customize report title for your project
- Helps identify different runs
- Appears at top of MultiQC HTML report

## Generic Options

### --help

**Type:** Boolean
**Default:** `false`
**Description:** Display help message and exit

**Example:**
```bash
nextflow run main.nf --help
```

**Output:**
- Usage information
- Parameter descriptions
- Example commands

### --version

**Type:** Boolean
**Default:** `false`
**Description:** Display pipeline version and exit

**Example:**
```bash
nextflow run main.nf --version
```

### --validate_params

**Type:** Boolean
**Default:** `true`
**Description:** Validate parameters against schema at runtime

**Example:**
```bash
# Enable validation (default)
--validate_params true

# Disable validation (not recommended)
--validate_params false
```

**Notes:**
- Validation catches errors before pipeline starts
- Recommended to keep enabled
- Checks parameter types, ranges, and requirements

## Advanced Options

### --validationShowHiddenParams

**Type:** Boolean
**Default:** `false`
**Description:** Show all parameters including hidden ones in help

**Example:**
```bash
nextflow run main.nf --help --validationShowHiddenParams
```

### --validationSchemaIgnoreParams

**Type:** String (comma-separated)
**Default:** `genomes,igenomes_base`
**Description:** Parameters to ignore during validation

**Example:**
```bash
--validationSchemaIgnoreParams "genomes,igenomes_base,custom_param"
```

## Parameter Precedence

Parameters can be set in multiple locations. Precedence (highest to lowest):

1. **Command line:** `--parameter value`
2. **Custom config:** `-c custom.config`
3. **Profile config:** `-profile slurm` (includes `conf/slurm.config`)
4. **Base config:** `nextflow.config`

**Example:**
```bash
# These override defaults in nextflow.config
nextflow run main.nf \
    --max_cpus 16 \           # Command line (highest priority)
    -c custom.config \        # Custom config
    -profile slurm            # Profile config
```

## Configuration Files vs Parameters

**Parameters** (`--param value`):
- User-facing options
- Documented in schema
- Validated automatically
- Set via command line

**Configuration** (in `.config` files):
- Process-specific settings
- Resource allocations
- Advanced options
- Set in config files

**Example:**
```bash
# Parameters (command line)
--max_memory 64.GB

# Configuration (in conf/base.config)
process {
    withName: 'UNICYCLER' {
        memory = { check_max( 32.GB * task.attempt, 'memory' ) }
    }
}
```

## Common Parameter Combinations

### Quick test run

```bash
nextflow run main.nf \
    --input test_samples.csv \
    --outdir test_results \
    -profile test,singularity
```

### Standard HPC run

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --max_cpus 16 \
    --max_memory 128.GB \
    -profile singularity,slurm \
    -resume
```

### High-quality assembly with Flye

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --use_flye \
    --genome_size 3m \
    --max_cpus 24 \
    --max_memory 256.GB \
    -profile singularity,slurm
```

### Local workstation run

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --max_cpus 8 \
    --max_memory 32.GB \
    -profile singularity,local
```

### Strict QC filtering

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --min_read_length 8000 \
    --filtlong_keep_percent 90 \
    -profile singularity,slurm
```

## See Also

- **Usage Guide:** [usage.md](usage.md)
- **Output Description:** [output.md](output.md)
- **Configuration Files:** [`conf/README.md`](../conf/README.md)
- **Parameter Schema:** [`nextflow.schema.json`](../nextflow.schema.json)
- **Main Config:** [`nextflow.config`](../nextflow.config)
