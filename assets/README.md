# Assets Directory

This directory contains configuration files and schemas used by the pipeline for validation and reporting.

## Files

| File | Purpose |
|------|---------|
| `schema_input.json` | Samplesheet validation schema (nf-schema) |
| `multiqc_config.yaml` | MultiQC report configuration |

## schema_input.json

**Purpose:** Validates the input samplesheet format and content

**Used by:** nf-schema plugin for automatic samplesheet validation

**Validation performed:**
- File format (CSV with required columns)
- Sample names (unique, no spaces)
- File paths (exist, absolute, correct extension)
- File types (`.fq.gz` or `.fastq.gz`)
- Required columns present

**Schema structure:**
```json
{
    "sample": {
        "type": "string",
        "pattern": "^[^\\s]+$"  # No spaces allowed
    },
    "nanopore": {
        "type": "string",
        "format": "file-path",
        "exists": true           # File must exist
    }
}
```

**Customization:**

To allow different file extensions:
```json
"pattern": "^\\S+\\.(fq|fastq)(\\.gz)?$"  # Allow uncompressed
```

To add optional columns:
```json
"required": ["sample", "nanopore", "illumina_1", "illumina_2"],
"properties": {
    ...existing properties...,
    "optional_field": {
        "type": "string"
    }
}
```

**Error messages:**

The schema provides clear error messages:
- "Sample name must not contain spaces"
- "File cannot contain spaces and must have extension '.fq.gz'"
- "File does not exist"

## multiqc_config.yaml

**Purpose:** Customizes the MultiQC aggregated report

**Used by:** MultiQC process to generate final HTML report

**Key sections:**

### 1. Report Metadata
```yaml
title: "Hybrid Assembly QC Report"
subtitle: "Illumina + Nanopore Bacterial Genome Assembly"
intro_text: |
    Pipeline workflow description...
```

### 2. Module Search Patterns
Tell MultiQC where to find tool outputs:
```yaml
sp:
    fastp:
        fn: '*.json'
    quast:
        fn: 'report.tsv'
```

### 3. Table Configuration
Control which columns appear in summary tables:
```yaml
table_columns_visible:
    fastp:
        pct_duplication: False  # Hide this column
    quast:
        'N50': True            # Show this column
```

### 4. Sample Name Cleaning
Remove suffixes for cleaner display:
```yaml
sample_names_replace:
    - '_trimmed'
    - '_porechop'
    - '_filtlong'
```

### 5. Quality Thresholds
Set pass/warn/fail thresholds for metrics:
```yaml
table_cond_formatting_rules:
    completeness:
        pass: [{gt: 95}]      # >95% is good
        warn: [{lt: 95}]      # <95% is warning
        fail: [{lt: 80}]      # <80% is fail
```

**Customization:**

### Adding New Tools

If you add a new tool to the pipeline:

1. Add search pattern:
```yaml
sp:
    your_tool:
        fn: 'output_pattern.txt'
        contents: 'Unique_String_In_Output'
```

2. Configure visible columns:
```yaml
table_columns_visible:
    your_tool:
        important_metric: True
        less_important: False
```

### Custom Report Branding

```yaml
# Add your logo
custom_logo: 'path/to/logo.png'
custom_logo_url: 'https://your-institution.edu'
custom_logo_title: 'Your Institution'

# Customize colors
custom_css_files:
    - 'custom_styles.css'
```

### Custom Data Parsing

For tools not natively supported by MultiQC:

```yaml
custom_data:
    my_custom_stats:
        file_format: 'tsv'
        section_name: 'Custom Statistics'
        description: 'Statistics from custom tool'
        plot_type: 'bargraph'
        pconfig:
            id: 'custom_stats_plot'
            title: 'Custom Stats'
```

## Usage in Pipeline

### Samplesheet Validation

Happens automatically at pipeline start:
```groovy
Include { samplesheetToList } from 'plugin/nf-schema'

Channel.fromList(samplesheetToList(params.input, "assets/schema_input.json"))
```

If validation fails:
- Pipeline stops immediately
- Clear error message displayed
- Points to problematic line/field

### MultiQC Report Generation

Used in MULTIQC process:
```groovy
MULTIQC(
    ch_multiqc_files.collect(),
    file("${projectDir}/assets/multiqc_config.yaml")
)
```

Results in customized report with:
- Custom title and branding
- Cleaned sample names
- Selected columns
- Quality threshold highlighting

## Best Practices

### For schema_input.json:

1. **Clear error messages:** Help users fix issues quickly
2. **Strict validation:** Catch errors before processing
3. **Informative patterns:** Document what's allowed
4. **Keep updated:** Match actual pipeline requirements

### For multiqc_config.yaml:

1. **Focus on key metrics:** Don't overwhelm with data
2. **Clear thresholds:** Set realistic pass/warn/fail values
3. **Clean names:** Remove technical suffixes
4. **Informative text:** Help users understand the report
5. **Test changes:** Always check report after config changes

## Testing Configuration

### Test Samplesheet Validation

Create intentionally invalid samplesheets to test:

```csv
# Test 1: Spaces in sample name
Bad Sample,/path/file.fq.gz,/path/R1.fq.gz,/path/R2.fq.gz

# Test 2: Non-existent file
Sample,/nonexistent/file.fq.gz,/path/R1.fq.gz,/path/R2.fq.gz

# Test 3: Wrong extension
Sample,/path/file.txt,/path/R1.fq.gz,/path/R2.fq.gz
```

Expected: Clear error messages for each issue

### Test MultiQC Config

After modifying `multiqc_config.yaml`:

```bash
# Run pipeline with test data
nextflow run main.nf -profile test,singularity

# Check report
open results/multiqc/multiqc_report.html

# Verify:
# - Title and subtitle are correct
# - Sample names are cleaned
# - Expected columns are visible
# - Quality thresholds work
```

## Troubleshooting

### Samplesheet validation fails unexpectedly
```
Check:
- File paths are absolute
- Files actually exist
- Extensions match pattern
- No hidden characters in CSV
```

### MultiQC doesn't find tool outputs
```
Solution:
- Check search patterns in sp: section
- Verify output file names match patterns
- Use more specific contents: field if needed
```

### MultiQC report missing data
```
Check:
- Tool outputs are being generated
- Files are in location MultiQC searches
- Search patterns are correct
- Check MultiQC logs for parsing errors
```

### Quality thresholds don't work
```
Solution:
- Check metric names match exactly
- Verify data type (numeric vs string)
- Test with known good/bad values
```

## See Also

- nf-schema plugin: https://nextflow-io.github.io/nf-schema/
- MultiQC documentation: https://multiqc.info/docs/
- JSON Schema reference: https://json-schema.org/
- Main pipeline configuration: `nextflow.config`
- Parameter schema: `nextflow.schema.json`
