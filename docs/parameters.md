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
9. [Common Parameter Combinations](#common-parameter-combinations)

## Parameter Overview

| Category | Required | Optional |
|----------|----------|----------|
| Input/Output | `--input`, `--outdir` | - |
| Assembly | - | `--assembly_mode`, `--genome_size`, `--reference` |
| QC | - | `--min_illumina_coverage`, `--min_nanopore_coverage`, `--min_read_length`, etc. |
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

## Assembly Options

### --assembly_mode

**Type:** String (enum)
**Default:** `unicycler`
**Valid values:** `unicycler`, `flye_unicycler`, `flye_polypolish`
**Description:** Assembly strategy to use

| Mode | Description |
|------|-------------|
| `unicycler` | Unicycler hybrid assembly using Illumina + Nanopore reads (default) |
| `flye_unicycler` | Flye long-read assembly → Unicycler with `--existing_long_read_assembly` |
| `flye_polypolish` | Flye long-read assembly → Polypolish (Illumina-based polishing) |

**Example:**
```bash
# Default (unicycler hybrid)
--assembly_mode unicycler

# Flye → Unicycler
--assembly_mode flye_unicycler

# Flye → Polypolish
--assembly_mode flye_polypolish
```

**When to use each mode:**

`unicycler` (default):
- Standard bacterial isolate genomes
- Sufficient Illumina + Nanopore coverage
- Fast turnaround needed

`flye_unicycler`:
- Complex repeat structures preventing Unicycler circularisation
- High-quality Nanopore data (Q15+, 50x+)
- Want Flye's graph resolution with Unicycler polishing

`flye_polypolish`:
- Unicycler cannot circularise due to high-copy repeats (confirmed by Flye circularising cleanly)
- High-quality Nanopore data (Q15+)
- Validated reference available for dnadiff QC

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
```

**Important:**
- Required for `flye_unicycler` and `flye_polypolish` modes
- Not used in `unicycler` mode
- Should be approximate; too far off can affect assembly quality

**Typical bacterial genome sizes:**
- Small bacteria: 1-2 Mb
- Average bacteria: 3-5 Mb
- Large bacteria: 6-10 Mb

### --reference

**Type:** String (file path)
**Default:** `null` (not required)
**Description:** Path to reference genome FASTA for dnadiff comparison

**Example:**
```bash
--reference /path/to/reference.fasta
--reference /qib/references/Listeria_monocytogenes_EGD-e.fasta
```

**Notes:**
- Only used when `--assembly_mode flye_polypolish` is set
- If omitted in flye_polypolish mode, dnadiff is skipped with a warning
- Not used in `unicycler` or `flye_unicycler` modes
- The file must exist if provided (validated at runtime)

## QC Options

### --min_illumina_coverage

**Type:** Integer
**Default:** `30`
**Description:** Minimum Illumina coverage required to pass the coverage gate

**Example:**
```bash
--min_illumina_coverage 30   # Default
--min_illumina_coverage 50   # Stricter
```

**Notes:**
- Samples below this threshold are excluded from assembly with a warning
- Coverage is calculated by seqkit against `--genome_size`

### --min_nanopore_coverage

**Type:** Integer
**Default:** `20`
**Description:** Minimum Nanopore coverage required to pass the coverage gate

**Example:**
```bash
--min_nanopore_coverage 20   # Default
--min_nanopore_coverage 40   # Stricter
```

**Notes:**
- Samples below this threshold are excluded from assembly with a warning
- Coverage is calculated by seqkit against `--genome_size`

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
**Default:** `${launchDir}/singularity_cache`
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

### Flye + Unicycler assembly

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --assembly_mode flye_unicycler \
    --genome_size 3m \
    --max_cpus 24 \
    --max_memory 256.GB \
    -profile singularity,slurm
```

### Flye + Polypolish assembly with reference QC

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    --assembly_mode flye_polypolish \
    --genome_size 3m \
    --reference /path/to/reference.fasta \
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
- **Parameter Schema:** [`nextflow_schema.json`](../nextflow_schema.json)
- **Main Config:** [`nextflow.config`](../nextflow.config)
