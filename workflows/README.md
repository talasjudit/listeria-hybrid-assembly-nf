# Workflows Directory

This directory contains the main pipeline workflow and auxiliary workflows.

## Files

| File | Status | Purpose |
|------|--------|---------|
| `main.nf` | ✅ Complete | Main hybrid assembly pipeline orchestration |
| `install.nf` | ✅ Complete | Download all Singularity containers |

## main.nf

**Status:** Fully implemented and tested (both standard and Flye modes)

**Purpose:** Orchestrates the complete hybrid assembly pipeline

### Pipeline Steps

1. **INPUT_CHECK** - Parse samplesheet and validate inputs
2. **FASTP** - Illumina read QC and trimming
3. **QC_NANOPORE** - Nanopore adapter removal and quality filtering (Porechop + Filtlong)
4. **FLYE** (optional) - Long-read de novo assembly
5. **ASSEMBLY_HYBRID** - Hybrid assembly with Unicycler
6. **QC_ASSEMBLY** - Assembly quality assessment (CheckM2 + QUAST)
7. **MULTIQC** - Aggregate all QC reports

### Usage

```bash
# Standard mode (Unicycler only)
nextflow run main.nf -profile singularity,slurm --input samplesheet.csv --outdir results

# With Flye pre-assembly
nextflow run main.nf -profile singularity,slurm --input samplesheet.csv --outdir results --use_flye
```

---

## install.nf

**Status:** Fully implemented and tested

**Purpose:** Downloads all Singularity containers required for the pipeline

### What It Does

1. **Downloads containers** from GHCR and Quay.io
2. **Checks existing files** - skips already downloaded containers (storeDir caching)
3. **Verifies downloads** - runs version command on each container
4. **Reports progress** - shows download status and final summary

### Features

**Resumable:**
- Checks if containers already exist
- Skips re-downloading existing files
- Can be interrupted and resumed

**Verified:**
- Validates each download
- Checks file size
- Reports any failures clearly

**Informative:**
- Progress updates for each container
- Final summary with file sizes
- Clear error messages if download fails

### Example Output

```
╔═══════════════════════════════════════════════════════════════╗
║           Container Installation Workflow                     ║
║               Hybrid Assembly Pipeline                        ║
╚═══════════════════════════════════════════════════════════════╝

Cache directory: ./singularity_cache
Containers to download: 8

════════════════════════════════════════════════════════════
Downloading: fastp-1.0.1.sif
Source: oras://ghcr.io/talasjudit/bsup-2555/fastp:1.0.1-1
════════════════════════════════════════════════════════════
✓ Successfully downloaded fastp-1.0.1.sif

✓ Container unicycler-0.5.1.sif already exists, skipping download
...

╔═══════════════════════════════════════════════════════════════╗
║              Installation Complete!                           ║
╚═══════════════════════════════════════════════════════════════╝

Successfully processed 8 containers:
  ✓ fastp-1.0.1.sif              (245.67 MB)
  ✓ multiqc-1.31.sif             (523.12 MB)
  ...

Cache directory: ./singularity_cache

Next steps:
1. Verify containers with: ls -lh ./singularity_cache
2. Run the pipeline with: nextflow run main.nf -profile singularity,slurm --input samplesheet.csv
```

### When to Run

**Required before first pipeline run:**
```bash
nextflow run workflows/install.nf --singularity_cachedir ./singularity_cache
```

**On HPC systems:**
- Run on login node (internet access required)
- Compute nodes often don't have internet access
- Containers are cached and reused

**After updates:**
- If container versions change
- If new tools are added
- Delete old containers first if needed

### Requirements

**Singularity/Apptainer:**
```bash
# Check if installed
singularity --version
# or
apptainer --version
```

**Internet access:**
- Direct connection to pull containers
- Access to ghcr.io and quay.io

**Disk space:**
- ~5-10 GB for all containers
- Check available space: `df -h`

### Configuration

**Default cache directory:**
```groovy
params.singularity_cachedir = './singularity_cache'
```

**Change via parameter:**
```bash
--singularity_cachedir /shared/containers
```

**Change in config:**
```groovy
params {
    singularity_cachedir = '/shared/containers'
}
```

### Container Sources

**GHCR (GitHub Container Registry):**
- Most containers
- Format: `oras://ghcr.io/talasjudit/bsup-2555/tool:version-build`

**Quay.io (BioContainers):**
- Unicycler
- Format: `docker://quay.io/biocontainers/tool:version--build`

### Troubleshooting

#### No internet connection
```
Error: Cannot pull container
Solution: Run on node with internet access (e.g., login node)
```

#### Container already exists but corrupt
```
Solution:
rm ./singularity_cache/problematic.sif
nextflow run workflows/install.nf
```

#### Disk space full
```
Error: No space left on device
Solution:
- Check space: df -h
- Clean up: delete old containers
- Use different location with more space
```

#### Permission denied
```
Error: Cannot write to cache directory
Solution:
- Check directory permissions
- Create directory manually: mkdir -p ./singularity_cache
- Use writable location
```

#### Download fails
```
Error: Pull failed for container X
Possible causes:
- Internet connection interrupted
- Container URL changed
- Registry temporarily unavailable

Solution:
- Check internet connection
- Wait and retry
- Verify container exists at source
```

### Advanced Usage

**Parallel downloads:**
```bash
# Downloads run in parallel automatically
# Control with -qs parameter
nextflow run workflows/install.nf -qs 4
```

**Specific cache directory:**
```bash
# Shared directory for multiple users
nextflow run workflows/install.nf \
    --singularity_cachedir /shared/singularity_cache
```

**Different work directory:**
```bash
# Use faster storage for work directory
nextflow run workflows/install.nf \
    -w /scratch/$USER/work
```

### Testing Installation

After installation, verify containers:

```bash
# List all containers
ls -lh ./singularity_cache/*.sif

# Test a container
singularity exec ./singularity_cache/fastp-1.0.1.sif fastp --version
```

Expected: Tool version displayed without errors

### Maintenance

**Update containers:**
1. Delete old versions
2. Update container URLs in `install.nf`
3. Run installation workflow

**Clean up old containers:**
```bash
# Remove all
rm ./singularity_cache/*.sif

# Remove specific version
rm ./singularity_cache/fastp-old-version.sif
```

**Verify integrity:**
```bash
# Check file sizes
ls -lh ./singularity_cache/

# Test each container
for sif in ./singularity_cache/*.sif; do
    echo "Testing: $sif"
    singularity exec $sif echo "OK"
done
```

## Future Workflows

Additional workflows that might be added:

### test.nf (Potential)
**Purpose:** Run all tests (modules + integration)
**Status:** Not yet implemented

### download_databases.nf (Potential)
**Purpose:** Download reference databases (if needed)
**Status:** Not needed (CheckM2 database in container)

### validate.nf (Potential)
**Purpose:** Validate pipeline outputs
**Status:** Could be added in Phase 3

## See Also

- **Main pipeline:** `main.nf`
- **Configuration:** `nextflow.config`
- **Container usage:** Defined in each module
- **Singularity docs:** https://sylabs.io/docs/
