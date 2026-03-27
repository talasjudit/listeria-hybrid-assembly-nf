# Test Data

## Committed files (always present)

These files are committed to the repository and used directly by module and subworkflow tests:

| File | Description | Used by |
|------|-------------|---------|
| `test_flye_assembly.fasta` | Flye draft assembly | unicycler, assembly_flye_unicycler, bwa_mem, polypolish, dnaapler, dnadiff (reference) tests |
| `test_flye_info.txt` | Flye assembly_info.txt | circularity_check tests (flye format) |
| `test_unicycler_assembly.fasta` | Unicycler hybrid assembly | circularity_check, dnadiff (assembly) tests |
| `test_flye_draft.report` | Minimal dnadiff report (draft: SNPs=542, Indels=98) | polishing_summary tests |
| `test_polypolish.report` | Minimal dnadiff report (polished: SNPs=142, Indels=38) | polishing_summary tests |
| `test_R1_small.fastq.gz` | Illumina R1 (10k read subset) | bwa_mem, polypolish, assembly_polypolish tests |
| `test_R2_small.fastq.gz` | Illumina R2 (10k read subset) | bwa_mem, polypolish, assembly_polypolish tests |
| `samplesheet_test.csv` | Samplesheet with relative paths | integration tests |
| `samplesheet_test_abs.csv` | Samplesheet with absolute QIB HPC paths | QIB HPC only |

Source sample: **BL07-034** (Listeria monocytogenes).
Assemblies generated using `tests/data/generate_test_assemblies.slurm`.

## Raw reads (not committed, optional)

Raw FASTQ files are gitignored and not stored in the repository. They are needed for
module tests that run actual tools (fastp, porechop, filtlong, flye, coverage_check)
and for integration tests.

Expected filenames:
```
tests/data/test_nanopore.fastq.gz
tests/data/test_R1.fastq.gz
tests/data/test_R2.fastq.gz
```

Download from ENA (BioProject PRJNA837734, sample BL07-034):
```bash
bash tests/data/download_test_data.sh
```

Tests that require raw reads will print a clear error if the files are not present.

## Regenerating committed assemblies

If the source reads change, regenerate the committed assemblies using:

```bash
sbatch tests/data/generate_test_assemblies.slurm
```

Then commit the updated FASTA files.
