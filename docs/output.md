# Output Documentation

This document describes all output files and directories produced by the hybrid assembly pipeline.

## Quick Reference

**Most important outputs:**
- 🔬 **Final assemblies:** `results/unicycler/`
- 📊 **QC report (start here):** `results/multiqc/multiqc_report.html`
- ✅ **Completeness:** `results/checkm2/`
- 📈 **Statistics:** `results/quast/`

## Output Directory Structure

```
results/
├── fastp/                      # Illumina QC (FastP)
│   ├── SAMPLE_R1_trimmed.fastq.gz
│   ├── SAMPLE_R2_trimmed.fastq.gz
│   ├── SAMPLE.json
│   └── SAMPLE.html
├── porechop/                   # Nanopore adapter removal
│   ├── SAMPLE_porechop.fastq.gz
│   └── SAMPLE_porechop.log
├── filtlong/                   # Nanopore quality filtering
│   ├── SAMPLE_filtlong.fastq.gz
│   └── SAMPLE_filtlong.log
├── flye/                       # Long-read assembly (if --use_flye)
│   ├── SAMPLE_flye.fasta
│   ├── SAMPLE_flye/
│   │   └── assembly_info.txt
│   └── SAMPLE_flye.log
├── unicycler/                  # ⭐ FINAL ASSEMBLIES
│   ├── SAMPLE_unicycler.fasta  # ← THIS IS YOUR ASSEMBLY
│   ├── SAMPLE_unicycler/
│   │   └── assembly.gfa
│   └── SAMPLE_unicycler.log
├── checkm2/                    # Assembly completeness
│   ├── SAMPLE_checkm2/
│   │   └── quality_report.tsv  # ← Completeness & contamination
│   └── SAMPLE_checkm2.log
├── quast/                      # Assembly statistics
│   ├── SAMPLE_quast/
│   │   ├── report.tsv          # ← Assembly metrics
│   │   └── report.html
│   └── SAMPLE_quast.log
├── multiqc/                    # ⭐ AGGREGATED REPORT
│   ├── multiqc_report.html     # ← START HERE
│   └── multiqc_data/
└── pipeline_info/              # Execution reports
    ├── execution_timeline.html
    ├── execution_report.html
    ├── execution_trace.txt
    └── pipeline_dag.svg
```

## Detailed Output Description

### 1. FastP - Illumina QC

**Directory:** `results/fastp/`

**Files per sample:**
- `SAMPLE_R1_trimmed.fastq.gz` - Trimmed forward reads
- `SAMPLE_R2_trimmed.fastq.gz` - Trimmed reverse reads
- `SAMPLE.json` - QC metrics (JSON format)
- `SAMPLE.html` - Interactive QC report

**What to check:**
- **Total reads:** Should have sufficient data (millions of reads)
- **Passing filter:** >95% is good
- **Adapter content:** Should be low after trimming (<1%)
- **Quality scores:** Should be Q30+ for most bases

**Example JSON metrics:**
```json
{
    "summary": {
        "before_filtering": {
            "total_reads": 10000000,
            "total_bases": 1500000000
        },
        "after_filtering": {
            "total_reads": 9800000,  // 98% passed
            "total_bases": 1450000000
        }
    }
}
```

**When to worry:**
- <90% reads passing filter
- High adapter contamination after filtering
- Very low quality scores

### 2. Porechop - Nanopore Adapter Removal

**Directory:** `results/porechop/`

**Files per sample:**
- `SAMPLE_porechop.fastq.gz` - Adapter-trimmed Nanopore reads
- `SAMPLE_porechop.log` - Adapter detection and removal log

**What to check in log:**
- Number of reads processed
- Adapters found and removed
- Chimeric reads removed

**Typical log contents:**
```
Total reads: 50000
Reads with adapters: 45000 (90%)
Chimeric reads removed: 500 (1%)
Final reads: 49500
```

### 3. Filtlong - Nanopore Quality Filtering

**Directory:** `results/filtlong/`

**Files per sample:**
- `SAMPLE_filtlong.fastq.gz` - Quality-filtered Nanopore reads
- `SAMPLE_filtlong.log` - Filtering statistics

**What to check in log:**
- Total bases kept
- Mean read length after filtering
- Percentage of reads kept

**Settings:**
- Default keeps top 95% of reads by quality
- Minimum read length: 6000 bp (default)

### 4. Flye - Long-Read Assembly

**Directory:** `results/flye/` (only if `--use_flye` is set)

**Files per sample:**
- `SAMPLE_flye.fasta` - Flye long-read assembly
- `SAMPLE_flye/assembly_info.txt` - Contig information
- `SAMPLE_flye.log` - Assembly log

**Assembly info format:**
```
#seq_name    length    cov    circ    repeat    ...
contig_1     2950000   45.2   Y       N         ...
contig_2     85000     40.1   N       N         ...
```

**Key metrics:**
- **circ:** Y = circular contig (complete replicon)
- **cov:** Coverage depth
- **repeat:** Y = identified as repeat region

**What to check:**
- Largest contig should be close to expected chromosome size
- Check for circular contigs (complete chromosomes)
- Coverage should be roughly uniform

### 5. Unicycler - Final Assembly

**Directory:** `results/unicycler/` ⭐ **MAIN OUTPUT**

**Files per sample:**
- `SAMPLE_unicycler.fasta` - **Final hybrid assembly**
- `SAMPLE_unicycler/assembly.gfa` - Assembly graph
- `SAMPLE_unicycler.log` - Detailed assembly log

**Assembly FASTA:**
This is your final genome assembly. Use this file for:
- Genome annotation
- Comparative genomics
- Submission to databases
- Further analyses

**Example FASTA:**
```
>1 length=2945000 depth=1.00x circular=true
ATGCATGCATGC...
>2 length=85000 depth=1.02x circular=true
GCTAGCTAGCTA...
```

**FASTA header information:**
- `length=` - Contig length in base pairs
- `depth=` - Relative coverage depth
- `circular=` - Whether contig circularized

**What to check:**
- Number of contigs (fewer is better)
- Largest contig (should be chromosome-sized)
- Circular contigs (complete replicons)
- Total assembly size (should match expected genome size)

**Assembly log:**
Contains detailed information about:
- Bridging operations
- Graph simplification
- Polish rounds
- Final statistics

### 6. CheckM2 - Assembly Completeness

**Directory:** `results/checkm2/`

**Files per sample:**
- `SAMPLE_checkm2/quality_report.tsv` - Completeness metrics
- `SAMPLE_checkm2.log` - Analysis log

**Quality report format:**
```
Name          Completeness    Contamination    ...
SAMPLE        98.5            0.8              ...
```

**Key metrics:**

**Completeness:**
- >95% = Excellent
- 90-95% = Good
- 80-90% = Acceptable
- <80% = Problematic

**Contamination:**
- <2% = Excellent
- 2-5% = Acceptable
- >5% = Problematic

**Combined quality score:**
- `Completeness - 5*Contamination`
- >90 = High quality
- 50-90 = Medium quality
- <50 = Low quality

**What to do if quality is low:**
- Check sequencing coverage
- Review input data quality
- Check for sample contamination
- Consider resequencing

### 7. QUAST - Assembly Statistics

**Directory:** `results/quast/`

**Files per sample:**
- `SAMPLE_quast/report.tsv` - Assembly statistics (TSV)
- `SAMPLE_quast/report.html` - Interactive report
- `SAMPLE_quast.log` - Analysis log

**Key metrics in report.tsv:**

| Metric | Description | Good Value |
|--------|-------------|------------|
| # contigs | Number of contigs | <50 for bacteria |
| Total length | Assembly size | Match expected genome |
| N50 | Half assembly in contigs ≥ this size | >100 Kb |
| L50 | Number of contigs in N50 | <10 |
| Largest contig | Biggest contig size | ~Chromosome size |
| GC (%) | GC content | Match expected |

**Example report:**
```
Metric                Value
# contigs             15
Total length          2,945,000
N50                   450,000
L50                   3
Largest contig        2,100,000
GC (%)                37.8
```

**Interpreting results:**

**Excellent assembly:**
- 1-20 contigs
- N50 >500 Kb
- Largest contig >2 Mb

**Good assembly:**
- <50 contigs
- N50 >100 Kb
- Total length matches expected

**Poor assembly:**
- >100 contigs
- N50 <50 Kb
- Fragmented

### 8. MultiQC - Aggregated Report

**Directory:** `results/multiqc/` ⭐ **START HERE**

**Files:**
- `multiqc_report.html` - **Interactive aggregated report**
- `multiqc_data/` - Raw data and plots

**What's included:**
- Summary of all QC metrics
- Plots comparing all samples
- Links to individual reports
- Assembly quality overview

**How to use:**
1. Open `multiqc_report.html` in web browser
2. Review "General Statistics" table
3. Check individual tool sections
4. Compare samples side-by-side
5. Identify outliers or problems

**Key sections:**
- **FastP:** Read quality and filtering
- **QUAST:** Assembly statistics
- **CheckM2:** Completeness (if integrated)

### 9. Pipeline Info - Execution Reports

**Directory:** `results/pipeline_info/`

**Files:**
- `execution_timeline.html` - Timeline of all processes
- `execution_report.html` - Resource usage summary
- `execution_trace.txt` - Detailed trace log
- `pipeline_dag.svg` - Workflow diagram

**Timeline report:**
- Shows when each process started/finished
- Identifies bottlenecks
- Useful for optimization

**Execution report:**
- Resource usage statistics
- CPU and memory utilization
- Process duration
- Success/failure status

**Trace file:**
Raw text file with all execution details:
```
task_id    status    duration    cpus    memory    ...
1          COMPLETED 10m         6       15.2 GB   ...
```

## Using the Outputs

### For Genome Annotation

Use the final assembly:
```bash
# Prokka annotation
prokka results/unicycler/SAMPLE_unicycler.fasta \
    --outdir annotation/ \
    --prefix SAMPLE

# PGAP annotation
# Submit SAMPLE_unicycler.fasta to NCBI PGAP
```

### For Quality Assessment

Check these three files:
1. `multiqc/multiqc_report.html` - Overall summary
2. `checkm2/SAMPLE_checkm2/quality_report.tsv` - Completeness
3. `quast/SAMPLE_quast/report.tsv` - Statistics

### For Database Submission

**Required files:**
- Assembly: `unicycler/SAMPLE_unicycler.fasta`
- Raw reads: Original FASTQ files
- QC reports: `multiqc/multiqc_report.html`

**NCBI GenBank submission:**
1. Clean contig names if needed
2. Add structured comment with assembly method
3. Include QC metrics

### For Comparative Genomics

**Use assemblies for:**
- Pan-genome analysis
- SNP calling
- Phylogenetic analysis
- Genome comparison

**Example tools:**
- Roary (pan-genome)
- Snippy (SNP calling)
- Mauve (alignment)
- BLAST (comparison)

## Quality Control Checklist

After pipeline completion, verify:

- [ ] MultiQC report generated successfully
- [ ] All samples present in output
- [ ] CheckM2 completeness >90% for all samples
- [ ] CheckM2 contamination <5% for all samples
- [ ] QUAST N50 >50 Kb
- [ ] Assembly size matches expected genome size (±10%)
- [ ] No failed processes in execution report

## Troubleshooting Outputs

### Missing output files

```
Check:
- Process completed successfully
- Check pipeline_info/execution_trace.txt
- Look for errors in .nextflow.log
```

### Empty assembly files

```
Cause: Assembly failed
Check:
- Input data quality and coverage
- Process logs in work/ directory
- Resource allocation
```

### Very fragmented assembly

```
Cause: Insufficient long-read data or quality
Solution:
- Check Nanopore coverage (need 50x+)
- Try --use_flye mode
- Check filtlong parameters
```

### High contamination

```
Cause: Sample contamination or mixed species
Check:
- Sample preparation
- FastP reports for unusual patterns
- Consider decontamination tools
```

## Best Practices

1. **Always check MultiQC first**
   - Gives overview of all samples
   - Easy to spot outliers

2. **Verify completeness and contamination**
   - Essential quality metrics
   - Determines if assembly is usable

3. **Compare assembly size to expected**
   - Too large = contamination or plasmids
   - Too small = incomplete assembly

4. **Keep all outputs**
   - Useful for troubleshooting
   - Required for methods section
   - Archive for reproducibility

5. **Document quality metrics**
   - Record in lab notebook
   - Include in publications
   - Share with collaborators

## See Also

- [Usage Guide](usage.md)
- [Parameters Reference](parameters.md)
- [Main README](../README.md)
