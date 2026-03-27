# Configuration Files

| File | Purpose |
|------|---------|
| `base.config` | Per-process resource allocations (CPU, memory, time) with `check_max()` scaling |
| `slurm.config` | Generic SLURM executor configuration |
| `qib.config` | QIB/NBI HPC partition (unified `qib-compute` queue, no time limit) |
| `local.config` | Local executor for development and small-scale runs |
| `test.config` | Reduced resources for testing |

## Usage

Profiles are combined with commas:

```bash
# QIB HPC
nextflow run main.nf -profile qib --input samplesheet.csv

# QIB HPC with test resources
nextflow run main.nf -profile test,qib --input samplesheet.csv

# Generic SLURM (add your own partition names via -c)
nextflow run main.nf -profile slurm -c my_hpc.config --input samplesheet.csv

# Local
nextflow run main.nf -profile local --input samplesheet.csv
```

Singularity is enabled in all profiles.

## Adjusting Resources

Resources are defined in `base.config` per process. Increase if processes consistently
time out or run out of memory. Use the execution trace to identify bottlenecks:

```
results/pipeline_info/execution_trace.txt
results/pipeline_info/execution_timeline.html
```

## Custom HPC Config

For HPCs other than QIB, copy `slurm.config` and update the partition name:

```groovy
process {
    queue = 'your_partition'
}
```

Then run with: `nextflow run main.nf -profile slurm -c my_hpc.config --input samplesheet.csv`
