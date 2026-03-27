# Hybrid Bacterial Genome Assembly Pipeline

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg)](https://sylabs.io/docs/)
[![CI](https://github.com/talasjudit/listeria-hybrid-assembly-nf/actions/workflows/ci.yml/badge.svg)](https://github.com/talasjudit/listeria-hybrid-assembly-nf/actions/workflows/ci.yml)

A Nextflow pipeline for hybrid assembly of bacterial genomes using Illumina short reads and Oxford Nanopore long reads.

## Pipeline Overview

```mermaid
---
config:
  theme: mc
  themeVariables:
    fontSize: 40px
    width: 100%
    height: 1200px
    secondaryColor: '#ffffff'
    tertiaryColor: '#ffffff'
    background: '#ffffff'
  background: '#ffffff'
  layout: elk
---
flowchart LR
    n3["Illumina reads"] --> n7["fastp"]
    n7 --> n8["Trimmed reads"]
    n1["Nanopore reads"] --> n5["porechop_abi"]
    n5 --> n9["Trimmed reads"]
    n9 --> n6["filtlong"]
    n6 --> n10["Filtered reads"]
    n8 & n10 --> n31(["Coverage check"])
    n31 --> n15{"assembly_mode"}
    n15 -- "unicycler\n(default)" --> n22["unicycler"]
    n15 -- "flye_unicycler" --> n11["flye"] --> n12["Long-read assembly"] --> n13["unicycler\n(scaffold)"]
    n15 -- "flye_polypolish" --> n11b["flye"] --> n12b["Long-read assembly"] --> n_poly["polypolish"]
    n22 --> n_dna["dnaapler"]
    n13 --> n_dna
    n_poly --> n_dna
    n_dna --> n23["Final assembly"]
    n23 --> n27["checkm2"] & n28["quast"]
    n23 --> n_dd["dnadiff x2 +\npolishing summary\n(optional)"]
    n27 & n28 & n_dd --> n30["multiqc"]
    n3@{ shape: in-out}
    n1@{ shape: in-out}
    n7@{ shape: proc}
    n8@{ shape: lean-r}
    n5@{ shape: proc}
    n9@{ shape: lean-r}
    n6@{ shape: proc}
    n10@{ shape: lean-r}
    n22@{ shape: proc}
    n11@{ shape: proc}
    n12@{ shape: lean-r}
    n13@{ shape: proc}
    n11b@{ shape: proc}
    n12b@{ shape: lean-r}
    n_poly@{ shape: proc}
    n_dna@{ shape: proc}
    n23@{ shape: lean-r}
    n27@{ shape: proc}
    n28@{ shape: proc}
    n_dd@{ shape: proc}
    n30@{ shape: lean-r}
    n15@{ shape: diam}
     n3:::data
     n1:::data
     n7:::process
     n8:::data
     n5:::process
     n9:::data
     n6:::process
     n10:::data
     n31:::checkpoint
     n15:::decision
     n22:::process
     n11:::process
     n12:::data
     n13:::process
     n11b:::process
     n12b:::data
     n_poly:::process
     n_dna:::process
     n23:::data
     n27:::process
     n28:::process
     n_dd:::process
     n30:::data
    classDef process fill:#bbdefb,stroke:#1976d2,color:black
    classDef data fill:#c8e6c9,stroke:#388e3c,color:black
    classDef decision fill:#d3d3d3,stroke:#666666,color:black
    classDef checkpoint fill:#f6cf92, stroke-width:1px, stroke-dasharray: 0, color:black
```

## Prerequisites

- **Nextflow** >= 23.04.0
- **Singularity/Apptainer**
- **Git**

## Quick Start

```bash
# Clone repository
git clone https://github.com/talasjudit/listeria-hybrid-assembly-nf.git
cd listeria-hybrid-assembly-nf

# Download containers (run on a node with internet access)
nextflow run main.nf -entry INSTALL -profile singularity

# If running on a node with no internet access, set this environment variable before running the pipeline
export NXF_OFFLINE=true

# Run pipeline
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  -profile singularity,qib
```

## Documentation

For full documentation, see the **[Wiki](https://github.com/talasjudit/listeria-hybrid-assembly-nf/wiki)**:

- [Installation](https://github.com/talasjudit/listeria-hybrid-assembly-nf/wiki/2.-Installation)
- [Configuration](https://github.com/talasjudit/listeria-hybrid-assembly-nf/wiki/3.-Configuration)
- [Pipeline Steps](https://github.com/talasjudit/listeria-hybrid-assembly-nf/wiki/4.-Pipeline-Steps)
- [Output Structure](https://github.com/talasjudit/listeria-hybrid-assembly-nf/wiki/5.-Output)

Or see the local docs:

- [Usage Guide](docs/usage.md)
- [Parameters Reference](docs/parameters.md)
- [Output Documentation](docs/output.md)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgements

Pipeline development assisted by AI pair programming (Claude/Gemini)
