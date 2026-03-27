# Integration Tests

End-to-end test of all three assembly modes using real sequencing data.

## Running the integration test

Edit the configuration paths at the top of the submission script, then run it
from the pipeline directory:

```bash
bash tests/integration/submit_integration_test.sh
```

This submits three SLURM jobs chained with `afterok` dependencies:

```
Job 1: unicycler       (runs immediately)
Job 2: flye_unicycler  (starts after job 1 succeeds)
Job 3: flye_polypolish (starts after job 2 succeeds)
```

Each job uses `nextflow run main.nf -resume`. Because jobs are chained back-to-back,
Nextflow's cache is used correctly: preprocessing steps (fastp, porechop, filtlong,
coverage_check) run once in job 1 and are cached for jobs 2 and 3.

## Running a single mode

To re-run or test just one mode (e.g., to verify a config change):

```bash
nextflow run main.nf \
    -profile singularity,qib \
    -resume SESSION_ID \
    -work-dir /path/to/work \
    --assembly_mode flye_polypolish \
    --genome_size 3m \
    --input tests/data/samplesheet_test.csv \
    --outdir /path/to/results \
    --reference /path/to/reference.fasta \
    --singularity_cachedir singularity_cache
```

Find the session ID with `nextflow log`.

## Test data

Raw FASTQ files are gitignored. The submission script stages them automatically
from your configured source paths. They are not deleted after the run so that
timestamps remain stable for subsequent `-resume` runs.

## Expected outputs

```
{RESULTS_BASE}/
├── assembly/{mode}/
│   ├── flye/                          # flye_unicycler + flye_polypolish only
│   ├── {mode}/                        # unicycler or polypolish logs
│   └── SAMPLE_dnaapler.fasta
└── qc/{mode}/
    ├── circularity/
    ├── checkm2/
    ├── quast/
    ├── dnadiff/                       # flye_polypolish + --reference only
    └── multiqc/multiqc_report.html
```

## Integration test status

All three modes passed on sample BL07-034 (2026-03-25).
