#!/usr/bin/env bash
#
# Integration test submission script.
#
# Submits three SLURM jobs — one per assembly mode — chained with afterok
# dependencies. Each job runs 'nextflow run main.nf -resume' independently.
# Because the jobs run back-to-back with no gap, -resume reliably picks up
# cached tasks from the previous mode with no session ID tracking needed.
#
# Usage (from the pipeline directory):
#   bash tests/integration/submit_integration_test.sh
#
# To run a single mode only, comment out the others below.
#
set -euo pipefail

# ============================================================
# Configuration — edit these paths for your environment
# ============================================================
PIPELINE_DIR="/path/to/listeria-hybrid-assembly-nf"
NANOPORE_FILE="/path/to/your_sample_nanopore.fastq.gz"
R1_FILE="/path/to/your_sample_R1.fastq.gz"
R2_FILE="/path/to/your_sample_R2.fastq.gz"
REFERENCE="/path/to/reference.fasta"   # used by flye_polypolish; set to "" to skip dnadiff
WORK_DIR="/path/to/scratch/listeria-nf-work/integration"
RESULTS_BASE="/path/to/scratch/integration_results"
# ============================================================

TEST_DATA_DIR="${PIPELINE_DIR}/tests/data"
SLURM_SCRIPT="${PIPELINE_DIR}/tests/integration/run_pipeline_mode.slurm"

# Stage test reads (idempotent — skipped if already present)
echo "Staging test reads..."
[ -f "${TEST_DATA_DIR}/test_nanopore.fastq.gz" ] || cp -p "${NANOPORE_FILE}" "${TEST_DATA_DIR}/test_nanopore.fastq.gz"
[ -f "${TEST_DATA_DIR}/test_R1.fastq.gz"       ] || cp -p "${R1_FILE}"       "${TEST_DATA_DIR}/test_R1.fastq.gz"
[ -f "${TEST_DATA_DIR}/test_R2.fastq.gz"       ] || cp -p "${R2_FILE}"       "${TEST_DATA_DIR}/test_R2.fastq.gz"
echo "Done"
echo ""

COMMON="PIPELINE_DIR=${PIPELINE_DIR},WORK_DIR=${WORK_DIR},RESULTS_BASE=${RESULTS_BASE}"

JOB1=$(sbatch --parsable \
    --export=ALL,${COMMON},ASSEMBLY_MODE=unicycler,REFERENCE= \
    "${SLURM_SCRIPT}")

JOB2=$(sbatch --parsable \
    --dependency=afterok:${JOB1} \
    --export=ALL,${COMMON},ASSEMBLY_MODE=flye_unicycler,REFERENCE= \
    "${SLURM_SCRIPT}")

JOB3=$(sbatch --parsable \
    --dependency=afterok:${JOB2} \
    --export=ALL,${COMMON},ASSEMBLY_MODE=flye_polypolish,REFERENCE=${REFERENCE} \
    "${SLURM_SCRIPT}")

echo "Integration test submitted:"
echo "  ${JOB1}  unicycler"
echo "  ${JOB2}  flye_unicycler  [after ${JOB1}]"
echo "  ${JOB3}  flye_polypolish [after ${JOB2}]"
echo ""
echo "Monitor : squeue -j ${JOB1},${JOB2},${JOB3}"
echo "Cancel  : scancel ${JOB1} ${JOB2} ${JOB3}"
echo ""
echo "Results:"
for mode in unicycler flye_unicycler flye_polypolish; do
    echo "  ${RESULTS_BASE}/qc/${mode}/multiqc/multiqc_report.html"
done
