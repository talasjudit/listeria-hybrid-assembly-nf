# Assets

| File | Purpose |
|------|---------|
| `schema_input.json` | Samplesheet validation schema used by the nf-schema plugin |
| `multiqc_config.yaml` | MultiQC report customisation (title, sample name cleaning, visible columns) |

## schema_input.json

Validates the input CSV at pipeline start. Checks that required columns are present,
file paths exist, and filenames end in `.fq.gz` or `.fastq.gz`. Errors are reported
with the line number and field that failed.

## multiqc_config.yaml

Controls the appearance and content of `results/qc/{assembly_mode}/multiqc/multiqc_report.html`.
Edit this file to:
- Change the report title or subtitle
- Show or hide specific metric columns

When adding a new module whose output should appear in the MultiQC report, mix the
output file into `ch_multiqc_files` in `workflows/main.nf` using
`.map { meta, file -> file }` before `.collect()`. Files with embedded `# id:` headers
are auto-discovered by MultiQC's custom_content module and do not need an `sp:` entry.
