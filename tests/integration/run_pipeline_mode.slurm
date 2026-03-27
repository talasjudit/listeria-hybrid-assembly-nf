#!/bin/bash
#SBATCH -p qib-compute
#SBATCH --mem 4G
#SBATCH -c 2
#SBATCH --job-name=listeria-nf
#SBATCH --time=24:00:00
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=YOUR_EMAIL
#
# Per-mode Nextflow job. Submitted by submit_integration_test.sh via SLURM
# job dependencies — do not submit this script directly.
#
# Variables received via sbatch --export:
#   ASSEMBLY_MODE   unicycler | flye_unicycler | flye_polypolish
#   PIPELINE_DIR    absolute path to pipeline checkout
#   WORK_DIR        Nextflow work directory (scratch space)
#   RESULTS_BASE    results output directory
#   REFERENCE       reference FASTA path (flye_polypolish only; empty to skip dnadiff)

set -euo pipefail

export NXF_OFFLINE=true

source activate nextflow
cd "${PIPELINE_DIR}"

# Build optional args
REFERENCE_ARG=""
[ -n "${REFERENCE:-}" ] && REFERENCE_ARG="--reference ${REFERENCE}"

echo "Assembly mode : ${ASSEMBLY_MODE}"
echo "Work dir      : ${WORK_DIR}"
echo "Results base  : ${RESULTS_BASE}"
echo ""

nextflow run main.nf \
    -profile singularity,qib \
    -resume \
    -work-dir "${WORK_DIR}" \
    --assembly_mode "${ASSEMBLY_MODE}" \
    --genome_size 3m \
    --input "${PIPELINE_DIR}/tests/data/samplesheet_test.csv" \
    --outdir "${RESULTS_BASE}" \
    --singularity_cachedir "${PIPELINE_DIR}/singularity_cache" \
    ${REFERENCE_ARG}

echo ""
echo "MultiQC report: ${RESULTS_BASE}/qc/${ASSEMBLY_MODE}/multiqc/multiqc_report.html"
