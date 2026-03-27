#!/bin/bash
#SBATCH -p qib-compute
#SBATCH --mem 4G
#SBATCH -c 2
#SBATCH --job-name=listeria-nf
#SBATCH --time=24:00:00
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=YOUR_EMAIL

# Example SLURM submission script for listeria-hybrid-assembly-nf
# The head job only needs minimal resources (4G, 2 CPUs) -- Nextflow
# submits each pipeline process as its own SLURM job automatically.
#
# See docs/usage.md for full parameter documentation.

# Activate nextflow environment
source activate nextflow

# Pipeline location — always cd here so launchDir and singularity_cachedir are stable
PIPELINE_DIR="/path/to/listeria-hybrid-assembly-nf"

cd "${PIPELINE_DIR}"

# Run in offline mode (containers must already be cached via: nextflow run main.nf -entry INSTALL -profile singularity,qib)
export NXF_OFFLINE=true

# --- Default mode: Unicycler hybrid assembly ---
nextflow run main.nf \
    -profile singularity,qib \
    --input /path/to/samplesheet.csv \
    --outdir /path/to/results \
    --singularity_cachedir "${PIPELINE_DIR}/singularity_cache"

# --- Alternative: Flye + Unicycler ---
# nextflow run main.nf \
#     -profile singularity,qib \
#     --input /path/to/samplesheet.csv \
#     --outdir /path/to/results \
#     --assembly_mode flye_unicycler \
#     --singularity_cachedir "${PIPELINE_DIR}/singularity_cache"

# --- Alternative: Flye + Polypolish (with optional reference comparison) ---
# nextflow run main.nf \
#     -profile singularity,qib \
#     --input /path/to/samplesheet.csv \
#     --outdir /path/to/results \
#     --assembly_mode flye_polypolish \
#     --reference /path/to/reference.fasta \
#     --singularity_cachedir "${PIPELINE_DIR}/singularity_cache"

# --- Custom work directory (recommended: use scratch space) ---
# nextflow run main.nf \
#     -profile singularity,qib \
#     -work-dir /qib/scratch/users/YOURUSER/listeria-nf-work \
#     --input /path/to/samplesheet.csv \
#     --outdir /path/to/results \
#     --singularity_cachedir "${PIPELINE_DIR}/singularity_cache"
