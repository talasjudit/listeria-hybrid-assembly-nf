# Local Subworkflows

Subworkflows that group related processes for the hybrid assembly pipeline.

## Subworkflow List

| Subworkflow | Purpose | Processes |
|-------------|---------|-----------|
| `input_check.nf` | Parse and validate samplesheet | nf-schema |
| `qc_nanopore.nf` | Nanopore QC | PORECHOP_ABI → FILTLONG |
| `assembly_unicycler.nf` | Unicycler hybrid assembly (default mode) | UNICYCLER |
| `assembly_flye_unicycler.nf` | Flye then Unicycler with existing assembly | FLYE → UNICYCLER |
| `assembly_polypolish.nf` | Flye then Polypolish Illumina polishing | FLYE → BWA_MEM → POLYPOLISH |
| `qc_assembly.nf` | Assembly quality assessment | CHECKM2 + QUAST (parallel) |

## Assembly Modes

The main workflow calls one assembly subworkflow based on `params.assembly_mode`:

| Mode | Subworkflow called |
|------|--------------------|
| `unicycler` (default) | `assembly_unicycler.nf` |
| `flye_unicycler` | `assembly_flye_unicycler.nf` |
| `flye_polypolish` | `assembly_polypolish.nf` |

## Notes

- `assembly_unicycler.nf` and `assembly_flye_unicycler.nf` both call UNICYCLER but with different inputs.
- `assembly_flye_unicycler.nf` passes the Flye FASTA via `--existing_long_read_assembly`.
- All three assembly subworkflows emit `assembly` (FASTA) and `versions`.
