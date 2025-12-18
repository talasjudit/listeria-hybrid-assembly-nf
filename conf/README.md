# Configuration Files

This directory contains configuration files for different execution environments and resource allocations.

## Files Overview

| File | Purpose |
|------|---------|
| `base.config` | Per-process resource allocations (CPU, memory, time) |
| `slurm.config` | Generic SLURM executor configuration (any HPC) |
| `qib.config` | QIB/NBI HPC-specific settings (partition names) |
| `local.config` | Local executor configuration for workstations |
| `test.config` | Moderate resources for testing with real data |

## Usage

Configurations are loaded via profiles in `nextflow.config`:

```bash
# QIB HPC execution (singularity auto-enabled)
nextflow run main.nf -profile qib --input samplesheet.csv

# QIB HPC testing
nextflow run main.nf -profile test,qib

# Local execution
nextflow run main.nf -profile test,local

# Generic SLURM (customize partitions with -c my_hpc.config)
nextflow run main.nf -profile slurm -c my_hpc.config --input samplesheet.csv
```

> **Note:** Singularity is auto-enabled in all profiles.

## base.config

**Purpose:** Define resource requirements for all pipeline processes

**Key features:**
- Per-process resource blocks (CPU, memory, time)
- Automatic scaling with `task.attempt` for retries
- `check_max()` function to enforce user-defined limits
- Error handling strategy (retry on resource errors)

**Customization:**
Adjust resources based on your data and infrastructure. Start conservative and increase as needed.

```groovy
withName: 'FASTP' {
    cpus   = { check_max( 6 * task.attempt, 'cpus' ) }
    memory = { check_max( 16.GB * task.attempt, 'memory' ) }
    time   = { check_max( 4.h * task.attempt, 'time' ) }
}
```

**When to modify:**
- Your samples are much larger/smaller than typical bacterial genomes
- Processes consistently run out of memory or time
- You want to optimize for faster execution with available resources

## slurm.config

**Purpose:** Generic SLURM configuration for any HPC system

**Key features:**
- SLURM executor settings
- Job submission rate limiting
- Singularity support (auto-enabled)
- Offline mode for compute nodes

**Note:** This is a generic config without partition names. For site-specific settings:
- Use `qib` profile for QIB/NBI HPC
- Create a custom config for other HPCs

**Creating a custom HPC config:**
```groovy
// my_hpc.config
process {
    queue = { task.time <= 2.h ? 'short' : 'long' }
    clusterOptions = '--account=YOUR_PROJECT'
}
```

Then run: `nextflow run main.nf -profile slurm -c my_hpc.config`

## qib.config

**Purpose:** QIB/NBI HPC-specific settings

**Key features:**
- Automatic partition selection:
  - `qib-short` for jobs ≤2 hours
  - `qib-medium` for jobs ≤48 hours  
  - `qib-long` for jobs >48 hours

**Usage:**
```bash
nextflow run main.nf -profile test,qib
nextflow run main.nf -profile qib --input samplesheet.csv
```

## local.config

**Purpose:** Configuration for local workstation or single-node server execution

**Key features:**
- Local executor with controlled parallelism (`maxForks`)
- Resource limits based on system capabilities
- Suitable for testing and small-scale runs

**Customization:**
Adjust `maxForks` based on your system:
```groovy
process {
    maxForks = 4  // Run up to 4 processes concurrently
}
```

**Recommended settings by system:**

Small workstation (8 cores, 16GB RAM):
```bash
--max_cpus 6 --max_memory 12.GB
```

Medium workstation (16 cores, 32GB RAM):
```bash
--max_cpus 12 --max_memory 24.GB
```

Large workstation (32 cores, 64GB RAM):
```bash
--max_cpus 24 --max_memory 48.GB
```

## test.config

**Purpose:** Minimal resources for testing with small datasets

**Key features:**
- Overrides all resources to minimal values
- Points to test data location
- Fast execution for validation
- Suitable for CI/CD pipelines

**Usage:**
```bash
nextflow run main.nf -profile test,singularity
```

**Do not use for:**
- Production runs
- Large datasets
- Parameter optimization

## Customizing for Your HPC System

### Step 1: Identify Your System

```bash
# Check SLURM version
sinfo --version

# List available partitions
sinfo

# Check your default account
sacctmgr show user $USER
```

### Step 2: Copy and Modify SLURM Config

```bash
# Create custom config
cp conf/slurm.config conf/my_hpc.config

# Edit partition names and account
vi conf/my_hpc.config
```

### Step 3: Add New Profile

Add to `nextflow.config`:
```groovy
profiles {
    my_hpc {
        includeConfig 'conf/base.config'
        includeConfig 'conf/my_hpc.config'
    }
}
```

### Step 4: Use New Profile

```bash
nextflow run main.nf -profile singularity,my_hpc --input samplesheet.csv
```

## Resource Optimization Tips

### 1. Start Conservative

Begin with default resources and increase only if needed:
- Monitor resource usage in execution reports
- Check SLURM efficiency: `seff JOBID`
- Review timeline for bottlenecks

### 2. Identify Bottlenecks

```bash
# Check execution timeline
open results/pipeline_info/execution_timeline.html

# Review resource usage
cat results/pipeline_info/execution_trace.txt
```

Look for:
- Processes taking much longer than expected
- Out of memory failures
- Processes queued for long time

### 3. Adjust Strategically

**If process runs out of memory:**
```groovy
// Increase memory allocation
withName: 'PROBLEMATIC_PROCESS' {
    memory = { check_max( 32.GB * task.attempt, 'memory' ) }
}
```

**If process is too slow:**
```groovy
// Increase CPUs if process scales well
withName: 'SLOW_PROCESS' {
    cpus = { check_max( 12 * task.attempt, 'cpus' ) }
}
```

**If process times out:**
```groovy
// Increase time limit
withName: 'LONG_PROCESS' {
    time = { check_max( 48.h * task.attempt, 'time' ) }
}
```

### 4. Test Changes

Always test configuration changes:
```bash
# Test with small dataset first
nextflow run main.nf -profile test,singularity

# Then test with one real sample
nextflow run main.nf --input one_sample.csv -profile singularity,slurm
```

## Common Configuration Patterns

### High-throughput Mode

For many samples on large HPC:
```groovy
executor {
    queueSize = 100
    submitRateLimit = '20 sec'
}
```

### Memory-constrained System

Reduce default memory allocations:
```groovy
params {
    max_memory = 64.GB
    max_cpus = 8
}
```

### Fast Turnaround

Use more aggressive resources:
```groovy
withName: 'UNICYCLER.*' {
    cpus = { check_max( 16 * task.attempt, 'cpus' ) }
    memory = { check_max( 64.GB * task.attempt, 'memory' ) }
}
```

## Troubleshooting

### Jobs fail with "Invalid partition"
```
Solution: Update partition names in slurm.config to match your system
Command: sinfo -o "%P" to see available partitions
```

### Jobs fail with "Invalid account"
```
Solution: Add your project account to clusterOptions
Check: sacctmgr show user $USER format=account
```

### Processes retry multiple times
```
Solution: Resource limits may be too low
Action: Check logs, increase appropriate resource in base.config
```

### Pipeline is too slow
```
Solution: Increase maxForks (local) or queueSize (SLURM)
Caution: Respect system policies and quotas
```

### Out of memory errors persist
```
Solution:
1. Check base.config resource allocations
2. Ensure max_memory parameter is adequate
3. Review data size - may need specialized resources
```

## Best Practices

1. **Version control:** Track config changes in git
2. **Document changes:** Add comments explaining modifications
3. **Test thoroughly:** Always test after config changes
4. **Start small:** Test with one sample before full run
5. **Monitor usage:** Review execution reports regularly
6. **Be conservative:** Better to over-allocate than fail mid-run
7. **Respect policies:** Follow HPC system usage guidelines

## See Also

- Main configuration: `nextflow.config`
- Parameter schema: `nextflow.schema.json`
- Usage documentation: `docs/usage.md`
- Resource monitoring: Check `results/pipeline_info/` after runs
