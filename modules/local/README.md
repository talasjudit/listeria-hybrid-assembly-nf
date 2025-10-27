# Local Modules

This directory contains custom process modules for the hybrid assembly pipeline. Each module wraps a specific bioinformatics tool and defines its inputs, outputs, and execution logic.

## Module List

| Module | Tool | Purpose | Status |
|--------|------|---------|--------|
| `fastp.nf` | fastp 1.0.1 | Illumina read QC and trimming | Template |
| `porechop_abi.nf` | Porechop ABI 0.5.0 | Nanopore adapter removal | Template |
| `filtlong.nf` | Filtlong 0.3.0 | Nanopore quality filtering | Template |
| `flye.nf` | Flye 2.9.6 | Long-read assembly | Template |
| `unicycler.nf` | Unicycler 0.5.1 | Standard hybrid assembly | Template |
| `unicycler_with_flye.nf` | Unicycler 0.5.1 | Hybrid with existing assembly | Template |
| `checkm2.nf` | CheckM2 1.1.0 | Assembly completeness | Template |
| `quast.nf` | QUAST 5.3.0 | Assembly statistics | Template |
| `multiqc.nf` | MultiQC 1.31 | Report aggregation | Template |

**Status:** All modules are currently templates with TODO comments for Phase 2+ implementation.

## Module Structure

Each module follows this standard structure:

```groovy
process MODULE_NAME {
    tag "$meta.id"                    // Label for process execution

    container "path/to/container.sif" // Singularity container

    input:
    tuple val(meta), path(files)      // Input data with metadata

    output:
    tuple val(meta), path('*.out'), emit: output_name
    path 'versions.yml'             , emit: versions

    when:
    task.ext.when == null || task.ext.when  // Conditional execution

    script:
    def args = task.ext.args ?: ''            // Additional arguments
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Tool command here
    tool_command input.fastq > output.fastq ${args}

    # Version capture
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tool: \$(tool --version)
    END_VERSIONS
    """

    stub:
    """
    touch output.file
    touch versions.yml
    """
}
```

## Key Design Principles

### 1. Metadata (`meta`)

Every module uses a `meta` map for sample information:

```groovy
meta = [
    id: 'sample_name',     // Unique sample identifier
    single_end: false      // true for single-end, false for paired-end
]
```

Benefits:
- Tracks sample identity through pipeline
- Enables sample-specific processing
- Allows joining channels by sample ID

### 2. Tuple Outputs

Outputs include metadata for downstream processing:

```groovy
output:
tuple val(meta), path('*.fastq.gz'), emit: reads
```

This allows:
- Easy channel joining: `.join(other_channel, by: 0)`
- Sample tracking throughout pipeline
- Flexible downstream operations

### 3. Named Emits

Use descriptive emit names:

```groovy
emit:
reads    = ch_reads      // Processed reads
report   = ch_report     // QC report
versions = ch_versions   // Software versions
```

### 4. Conditional Execution

The `when:` directive allows disabling processes:

```groovy
when:
task.ext.when == null || task.ext.when
```

Usage:
```groovy
process {
    withName: 'MODULE_NAME' {
        ext.when = { params.run_module }
    }
}
```

### 5. Version Tracking

Always capture tool versions:

```groovy
cat <<-END_VERSIONS > versions.yml
"${task.process}":
    toolname: \$(toolname --version 2>&1 | sed 's/toolname //g')
END_VERSIONS
```

### 6. Stub Mode

Provide stubs for testing workflow logic:

```groovy
stub:
def prefix = task.ext.prefix ?: "${meta.id}"
"""
touch ${prefix}.output
touch versions.yml
"""
```

## Using Modules

### Direct Import

Import and use a module in a workflow:

```groovy
include { FASTP } from './modules/local/fastp'

workflow {
    ch_reads = Channel.fromPath('*.fastq.gz')
        .map { file -> [[id: file.baseName], file] }

    FASTP(ch_reads)

    FASTP.out.reads.view()
}
```

### Multiple Imports

Import multiple modules:

```groovy
include { FASTP } from './modules/local/fastp'
include { PORECHOP_ABI } from './modules/local/porechop_abi'
include { FILTLONG } from './modules/local/filtlong'
```

### With Aliases

Use same module multiple times with different configs:

```groovy
include { FASTP as FASTP_RAW } from './modules/local/fastp'
include { FASTP as FASTP_CLEAN } from './modules/local/fastp' addParams(
    options: [args: '--different_params']
)
```

## Module Configuration

### Resource Allocation

Resources are configured in `conf/base.config`:

```groovy
process {
    withName: 'FASTP' {
        cpus   = { check_max( 6 * task.attempt, 'cpus' ) }
        memory = { check_max( 16.GB * task.attempt, 'memory' ) }
        time   = { check_max( 4.h * task.attempt, 'time' ) }
    }
}
```

### Additional Arguments

Pass extra arguments to tools:

```groovy
process {
    withName: 'FASTP' {
        ext.args = '--cut_front --cut_tail'
    }
}
```

### Conditional Execution

Enable/disable modules:

```groovy
process {
    withName: 'FLYE' {
        ext.when = { params.use_flye }
    }
}
```

## Module Development Guidelines

### Phase 2 Implementation Checklist

When implementing a module:

- [ ] Replace TODO placeholders with actual commands
- [ ] Test with real data
- [ ] Verify all outputs are produced
- [ ] Check output file formats
- [ ] Ensure version capture works
- [ ] Test stub mode
- [ ] Add input validation if needed
- [ ] Document any caveats or special requirements
- [ ] Test with different resource allocations
- [ ] Verify error handling

### Best Practices

1. **Clear naming:** Use descriptive variable names
2. **Comment thoroughly:** Explain complex logic
3. **Error handling:** Check for common failure modes
4. **Validate inputs:** Catch problems early
5. **Standard outputs:** Follow consistent naming
6. **Resource efficiency:** Don't over-allocate
7. **Container paths:** Use params.singularity_cachedir
8. **Version capture:** Always include tool versions

### Testing Modules

Each module should have a test workflow in `tests/modules/`:

```bash
# Test a module
nextflow run tests/modules/fastp/test_fastp.nf -profile test,singularity
```

## Common Patterns

### Input: Paired-end Reads

```groovy
input:
tuple val(meta), path(reads)  // reads = [R1.fq.gz, R2.fq.gz]

script:
"""
tool --forward ${reads[0]} --reverse ${reads[1]}
"""
```

### Input: Multiple File Types

```groovy
input:
tuple val(meta), path(illumina), path(nanopore)

script:
"""
tool --short ${illumina[0]} ${illumina[1]} --long ${nanopore}
"""
```

### Output: Directory with Multiple Files

```groovy
output:
tuple val(meta), path('output_dir/'), emit: results

script:
"""
mkdir output_dir
tool --output output_dir/ input.fastq
"""
```

### Conditional File Processing

```groovy
script:
def optional_input = params.use_reference ? "--reference ${reference}" : ""
"""
tool input.fastq ${optional_input} > output.txt
"""
```

## Module-Specific Notes

### FASTP
- Handles paired-end Illumina reads
- Automatic adapter detection
- Outputs: trimmed reads, JSON, HTML

### PORECHOP_ABI
- Nanopore adapter removal
- Use `--ab_initio` for best results
- Single-threaded parts may be slow

### FILTLONG
- Quality-based read filtering
- Uses params.min_read_length
- Outputs to stdout (pipe to gzip)

### FLYE
- Memory-intensive (monitor usage)
- Needs params.genome_size
- Creates multiple output files

### UNICYCLER vs UNICYCLER_WITH_FLYE
- Different input structures
- Same outputs
- Choose based on params.use_flye

### CHECKM2
- Requires CheckM2 database
- Database included in container
- Memory-intensive

### QUAST
- Fast execution
- Multiple output formats
- Can run without reference

### MULTIQC
- Collects all QC files
- Uses config from assets/
- Run once at end of pipeline

## Troubleshooting

### Module won't import
```
Check:
- File path is correct
- Module file exists
- No syntax errors in module
```

### Container not found
```
Solution:
- Run workflows/install.nf first
- Check params.singularity_cachedir
- Verify container filename matches
```

### Wrong number of outputs
```
Check:
- Output declarations match script
- Files are actually created
- Glob patterns match files
```

### Version capture fails
```
Solution:
- Test version command separately
- Check stderr vs stdout
- Use correct parsing (sed/awk)
```

## See Also

- **Subworkflows:** `subworkflows/local/README.md`
- **Configuration:** `conf/README.md`
- **Testing:** `tests/README.md`
- **Main workflow:** `main.nf`
- **Nextflow docs:** https://www.nextflow.io/docs/latest/process.html
