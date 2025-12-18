# Local Subworkflows

This directory contains subworkflows that group related processes or handle complex logic. Subworkflows are only created when they add significant value over using modules directly.

## Design Philosophy

**✅ Create a subworkflow when:**
- Multiple processes always run together in sequence
- Complex conditional logic spans multiple processes
- Significant channel manipulation is required
- Logic should be reusable or testable independently

**❌ Don't create a subworkflow for:**
- Single process with no dependencies
- Simple, straightforward steps
- Already clear logic in main workflow

## Subworkflow List

| Subworkflow | Purpose | Processes | Complexity |
|-------------|---------|-----------|------------|
| `input_check.nf` | Parse and validate samplesheet | nf-schema parsing | Complex parsing |
| `qc_nanopore.nf` | Nanopore QC pipeline | PORECHOP_ABI → FILTLONG | Sequential chain |
| `assembly_hybrid.nf` | Conditional assembly logic | UNICYCLER (Standard or Flye mode) | Conditional execution |
| `qc_assembly.nf` | Assembly quality assessment | CHECKM2 + QUAST (parallel) | Parallel execution |

## Why These Subworkflows?

### INPUT_CHECK
**Why a subworkflow:**
- Complex CSV parsing with validation
- Creates multiple output channels (Illumina, Nanopore)
- Channel manipulation (splitting, mapping)
- Reusable for different entry points

**Alternative:** Could be in main.nf, but would clutter the workflow

### QC_NANOPORE
**Why a subworkflow:**
- Two processes always run together (PORECHOP_ABI → FILTLONG)
- Sequential dependency (output of one feeds the other)
- Logical grouping: "Nanopore QC" is a single conceptual step
- Cleaner main workflow

**Alternative:** Call modules directly in main.nf (would work, but less organized)

### ASSEMBLY_HYBRID
**Why a subworkflow:**
- Complex conditional logic (standard vs with Flye)
- Two different processes with same purpose
- Hides implementation details from main workflow
- Makes assembly strategy decision explicit

**Alternative:** Conditional logic in main.nf (would be messy and confusing)

### QC_ASSEMBLY
**Why a subworkflow:**
- Two processes always run together (CHECKM2 + QUAST)
- Both analyze same input (assembly)
- Run in parallel (independent)
- Logical grouping: "Assembly QC"

**Alternative:** Call modules directly in main.nf (would work, but less clear)

## What We DON'T Have (And Why)

### No QC_ILLUMINA Subworkflow
**Why not:**
- Only one process (FASTP)
- No complexity to hide
- Called directly from main.nf

### No ASSEMBLY_FLYE Subworkflow
**Why not:**
- Single process (FLYE)
- Simple conditional execution
- Handled directly in main.nf

### No REPORT Subworkflow
**Why not:**
- Single process (MULTIQC)
- Just collects files
- No logic to encapsulate

## Subworkflow Structure

Standard subworkflow structure:

```groovy
// Import required modules
include { MODULE_A } from '../../modules/local/module_a'
include { MODULE_B } from '../../modules/local/module_b'

workflow SUBWORKFLOW_NAME {

    take:
    input_channel    // Description of input

    main:
    // Process execution logic
    MODULE_A(input_channel)
    MODULE_B(MODULE_A.out.output)

    // Channel operations
    ch_combined = MODULE_A.out.output1
        .mix(MODULE_B.out.output1)

    emit:
    output1 = ch_output1    // Description
    output2 = ch_output2    // Description
}
```

## Using Subworkflows

### Import and Use

```groovy
include { QC_NANOPORE } from './subworkflows/local/qc_nanopore'

workflow {
    ch_nanopore = Channel.fromPath('*.fastq.gz')
        .map { file -> [[id: file.baseName], file] }

    QC_NANOPORE(ch_nanopore)

    ch_qc_reads = QC_NANOPORE.out.reads
    ch_logs = QC_NANOPORE.out.logs
}
```

### Multiple Imports

```groovy
include { INPUT_CHECK } from './subworkflows/local/input_check'
include { QC_NANOPORE } from './subworkflows/local/qc_nanopore'
include { ASSEMBLY_HYBRID } from './subworkflows/local/assembly_hybrid'
```

### In Main Workflow

Subworkflows make main.nf much cleaner:

**Without subworkflows:**
```groovy
// Messy main.nf
PORECHOP_ABI(ch_nanopore)
FILTLONG(PORECHOP_ABI.out.reads)

if (params.use_flye) {
    ch_combined = ch_illumina.join(FILTLONG.out.reads)
    ch_with_flye = ch_combined.join(ch_flye_assembly)
    UNICYCLER(ch_with_flye) // Configured for Flye
    ch_assembly = UNICYCLER.out.assembly
} else {
    ch_combined = ch_illumina.join(FILTLONG.out.reads)
    UNICYCLER(ch_combined)
    ch_assembly = UNICYCLER.out.assembly
}

CHECKM2(ch_assembly)
QUAST(ch_assembly)
```

**With subworkflows:**
```groovy
// Clean main.nf
QC_NANOPORE(ch_nanopore)
ASSEMBLY_HYBRID(ch_illumina, QC_NANOPORE.out.reads, ch_flye)
QC_ASSEMBLY(ASSEMBLY_HYBRID.out.assembly)
```

Much clearer!

## Subworkflow Details

### INPUT_CHECK

**Purpose:** Parse samplesheet and create data channels

**Inputs:**
- `samplesheet`: Path to CSV file

**Outputs:**
- `illumina`: `tuple val(meta), path([R1, R2])`
- `nanopore`: `tuple val(meta), path(nanopore)`

**Key operations:**
- CSV parsing with nf-schema
- Metadata creation
- Channel splitting

**Example:**
```groovy
INPUT_CHECK(file(params.input))
ch_illumina = INPUT_CHECK.out.illumina
ch_nanopore = INPUT_CHECK.out.nanopore
```

### QC_NANOPORE

**Purpose:** Quality control for Nanopore reads

**Inputs:**
- `reads`: `tuple val(meta), path(reads)`

**Outputs:**
- `reads`: QC'd Nanopore reads
- `logs`: Log files from both processes
- `versions`: Version files

**Process flow:**
```
Nanopore reads → PORECHOP_ABI → FILTLONG → QC'd reads
```

**Example:**
```groovy
QC_NANOPORE(ch_nanopore_raw)
ch_nanopore_clean = QC_NANOPORE.out.reads
```

### ASSEMBLY_HYBRID

**Purpose:** Execute appropriate Unicycler mode based on params.use_flye

**Inputs:**
- `illumina_reads`: Trimmed Illumina reads
- `nanopore_reads`: QC'd Nanopore reads
- `flye_assembly`: Flye assembly (optional/empty)

**Outputs:**
- `assembly`: Final assembly FASTA
- `gfa`: Assembly graph
- `log`: Assembly log
- `versions`: Versions

**Decision logic:**
```
if params.use_flye:
    UNICYCLER(illumina, nanopore, flye)
else:
    UNICYCLER(illumina, nanopore)
```

**Example:**
```groovy
ASSEMBLY_HYBRID(
    ch_illumina_trimmed,
    ch_nanopore_filtered,
    ch_flye_assembly
)
ch_assemblies = ASSEMBLY_HYBRID.out.assembly
```

### QC_ASSEMBLY

**Purpose:** Parallel quality assessment of assemblies

**Inputs:**
- `assemblies`: `tuple val(meta), path(assembly)`

**Outputs:**
- `checkm2_reports`: Completeness reports
- `quast_reports`: Statistics reports
- `logs`: Log files
- `versions`: Versions

**Process flow:**
```
Assembly → CHECKM2 (completeness)
        → QUAST (statistics)
```

**Example:**
```groovy
QC_ASSEMBLY(ch_assemblies)
ch_completeness = QC_ASSEMBLY.out.checkm2_reports
ch_stats = QC_ASSEMBLY.out.quast_reports
```

## Advanced Channel Operations

Subworkflows often perform complex channel manipulations:

### Joining Channels by Sample ID

```groovy
ch_combined = ch_illumina
    .join(ch_nanopore, by: 0)
// Result: [meta, [R1, R2], nanopore]
```

### Mixing Outputs

```groovy
ch_all_logs = PORECHOP_ABI.out.log
    .mix(FILTLONG.out.log)
```

### Branching Channels

```groovy
ch_input
    .branch {
        with_flye: params.use_flye
        standard: !params.use_flye
    }
    .set { ch_branched }
```

### Collecting Files

```groovy
ch_reports
    .collect()  // Gather all files into single list
```

## Testing Subworkflows

Each subworkflow should be testable independently:

```groovy
// Test QC_NANOPORE
include { QC_NANOPORE } from './subworkflows/local/qc_nanopore'

workflow test_qc_nanopore {
    ch_test = Channel.of([
        [id: 'test'],
        file('test_data/nanopore.fq.gz')
    ])

    QC_NANOPORE(ch_test)
}
```

## Best Practices

### 1. Clear Interfaces

Define clear take/emit blocks:

```groovy
take:
reads          // tuple val(meta), path(reads) - raw reads

emit:
qc_reads       // tuple val(meta), path(reads) - QC'd reads
logs           // path(log) - all log files
versions       // path(yml) - version info
```

### 2. Self-Contained

Subworkflows should be self-contained:
- Import all required modules
- Don't rely on external channels
- Document all assumptions

### 3. Documentation

Include comprehensive comments:
- Purpose of subworkflow
- Input/output formats
- Process flow diagram
- Usage examples

### 4. Logical Grouping

Group processes that:
- Always run together
- Form a logical unit
- Have sequential dependencies

### 5. Don't Over-Abstract

Avoid creating subworkflows that:
- Just wrap a single module
- Make code harder to understand
- Add complexity without benefit

## Common Patterns

### Sequential Processing

```groovy
MODULE_A(input)
MODULE_B(MODULE_A.out.output)
MODULE_C(MODULE_B.out.output)
```

### Parallel Processing

```groovy
MODULE_A(input)
MODULE_B(input)  // Independent of MODULE_A

ch_combined = MODULE_A.out.output
    .mix(MODULE_B.out.output)
```

### Conditional Execution

```groovy
if (params.flag) {
    MODULE_A(input)
    ch_output = MODULE_A.out.output
} else {
    MODULE_B(input)
    ch_output = MODULE_B.out.output
}
```

## Troubleshooting

### Channel dimension mismatch
```
Issue: Subworkflow outputs don't match expected format
Solution: Add .view() to inspect channel structure
Check: tuple vs single value, list dimensions
```

### Missing outputs
```
Issue: Emit channel is empty
Solution: Check process outputs are actually generated
Verify: Output paths match glob patterns
```

### Conditional not working
```
Issue: Wrong branch executed
Solution: Add debug prints to verify condition
Check: Params are set correctly
```

## See Also

- **Modules:** `modules/local/README.md`
- **Main workflow:** `main.nf`
- **Testing:** `tests/README.md`
- **Nextflow docs:** https://www.nextflow.io/docs/latest/workflow.html
