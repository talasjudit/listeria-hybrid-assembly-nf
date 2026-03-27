#!/bin/bash
#SBATCH -p qib-compute
#SBATCH --mem 4G
#SBATCH -c 2
#SBATCH --job-name=listeria-nf-testdata
#SBATCH --time=12:00:00
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=YOUR_EMAIL

# ============================================================
# Generate test data files for listeria-hybrid-assembly-nf
#
# Produces three types of committed test data from BL07-034:
#   1. Assembly FASTAs (Flye + Unicycler) - for dnaapler, dnadiff,
#      circularity_check, and subworkflow tests
#   2. Subsampled Illumina reads (10k pairs) - for BWA/Polypolish tests
#
# Committed outputs:
#   tests/data/test_flye_assembly.fasta
#   tests/data/test_flye_info.txt
#   tests/data/test_unicycler_assembly.fasta
#   tests/data/test_R1_small.fastq.gz
#   tests/data/test_R2_small.fastq.gz
#
# Steps 2 and 3 (assembly generation) are skipped if the output files
# already exist. Run with --force to regenerate them.
#
# Usage:
#   sbatch tests/data/generate_test_assemblies.slurm
#   sbatch tests/data/generate_test_assemblies.slurm --force
#
# ============================================================

set -euo pipefail

export NXF_OFFLINE=true

# --- Configuration: edit these paths for your environment ---
RAW_DATA_DIR="/path/to/your/raw/data"
PIPELINE_MOUNT="/path/to/listeria-hybrid-assembly-nf"
NANOPORE_FILE="${RAW_DATA_DIR}/your_sample_nanopore.fastq.gz"
R1_FILE="${RAW_DATA_DIR}/your_sample_R1.fastq.gz"
R2_FILE="${RAW_DATA_DIR}/your_sample_R2.fastq.gz"

SAMPLE_ID="your_sample_id"
SUBSAMPLE_N=10000   # read pairs to keep for BWA/Polypolish tests
SUBSAMPLE_SEED=42   # fixed seed for reproducibility

# --- Paths (do not edit) ---
PIPELINE_DIR="${PIPELINE_MOUNT}"
TEST_DATA_DIR="${PIPELINE_DIR}/tests/data"
WORK_DIR="/path/to/scratch/listeria-nf-work/generate_assemblies"
SEQKIT_SIF="${PIPELINE_DIR}/singularity_cache/seqkit-2.12.0.sif"

# --- Parse arguments ---
FORCE=false
for arg in "$@"; do
    if [ "${arg}" == "--force" ]; then FORCE=true; fi
done

source activate nextflow
cd "${PIPELINE_DIR}"

echo "============================================================"
echo "Generating test data from sample: ${SAMPLE_ID}"
echo "Pipeline dir : ${PIPELINE_DIR}"
echo "Raw data dir : ${RAW_DATA_DIR}"
echo "Force regen  : ${FORCE}"
echo "============================================================"
echo ""

# ============================================================
# Step 1: Stage raw reads
# ============================================================
echo "--- Step 1: Staging raw reads ---"
cp "${NANOPORE_FILE}" "${TEST_DATA_DIR}/test_nanopore.fastq.gz"
cp "${R1_FILE}"       "${TEST_DATA_DIR}/test_R1.fastq.gz"
cp "${R2_FILE}"       "${TEST_DATA_DIR}/test_R2.fastq.gz"
echo "OK"

# ============================================================
# Step 2: Generate Flye assembly
# (skipped if test_flye_assembly.fasta already exists and --force not set)
# ============================================================
echo ""
echo "--- Step 2: Flye assembly ---"
if [ -f "${TEST_DATA_DIR}/test_flye_assembly.fasta" ] && [ "${FORCE}" == "false" ]; then
    echo "SKIP: test_flye_assembly.fasta already exists (use --force to regenerate)"
else
    nextflow run tests/modules/flye/test_flye.nf \
        -c nextflow.config \
        -profile singularity,qib \
        -work-dir "${WORK_DIR}/flye" \
        --outdir "${WORK_DIR}/flye_results"

    FLYE_WORK=$(nextflow log last -f workdir,process | awk '$2 == "FLYE" {print $1; exit}')
    if [ -z "${FLYE_WORK}" ]; then
        echo "ERROR: Could not find FLYE work directory in nextflow log"
        exit 1
    fi
    echo "Flye work dir: ${FLYE_WORK}"
    cp "${FLYE_WORK}"/*_flye.fasta    "${TEST_DATA_DIR}/test_flye_assembly.fasta"
    cp "${FLYE_WORK}"/*_flye_info.txt "${TEST_DATA_DIR}/test_flye_info.txt"
    echo "OK: test_flye_assembly.fasta, test_flye_info.txt"
fi

# ============================================================
# Step 3: Generate Unicycler assembly
# (skipped if test_unicycler_assembly.fasta already exists and --force not set)
# ============================================================
echo ""
echo "--- Step 3: Unicycler assembly ---"
if [ -f "${TEST_DATA_DIR}/test_unicycler_assembly.fasta" ] && [ "${FORCE}" == "false" ]; then
    echo "SKIP: test_unicycler_assembly.fasta already exists (use --force to regenerate)"
else
    nextflow run tests/modules/unicycler/test_unicycler.nf \
        -c nextflow.config \
        -profile singularity,qib \
        -work-dir "${WORK_DIR}/unicycler" \
        --outdir "${WORK_DIR}/unicycler_results"

    # UNICYCLER (standard hybrid) vs UNICYCLER_FLYE (aliased) — grab the standard run
    UNI_WORK=$(nextflow log last -f workdir,process | awk '$2 == "UNICYCLER" {print $1; exit}')
    if [ -z "${UNI_WORK}" ]; then
        echo "ERROR: Could not find UNICYCLER work directory in nextflow log"
        exit 1
    fi
    echo "Unicycler work dir: ${UNI_WORK}"
    cp "${UNI_WORK}"/*_unicycler.fasta "${TEST_DATA_DIR}/test_unicycler_assembly.fasta"
    echo "OK: test_unicycler_assembly.fasta"
fi

# ============================================================
# Step 4: Subsample Illumina reads for BWA/Polypolish tests
# 10k paired-end reads (~0.5x coverage of 3 Mb genome with 150 bp reads)
# Enough for the pipeline to run; not intended to produce a meaningful assembly
# (skipped if output files already exist and --force not set)
# ============================================================
echo ""
echo "--- Step 4: Subsampling Illumina reads (${SUBSAMPLE_N} pairs, seed ${SUBSAMPLE_SEED}) ---"
if [ -f "${TEST_DATA_DIR}/test_R1_small.fastq.gz" ] && [ "${FORCE}" == "false" ]; then
    echo "SKIP: test_R1_small.fastq.gz already exists (use --force to regenerate)"
else
    singularity exec "${SEQKIT_SIF}" \
        seqkit sample -n ${SUBSAMPLE_N} -s ${SUBSAMPLE_SEED} \
        "${TEST_DATA_DIR}/test_R1.fastq.gz" \
        -o "${TEST_DATA_DIR}/test_R1_small.fastq.gz"

    singularity exec "${SEQKIT_SIF}" \
        seqkit sample -n ${SUBSAMPLE_N} -s ${SUBSAMPLE_SEED} \
        "${TEST_DATA_DIR}/test_R2.fastq.gz" \
        -o "${TEST_DATA_DIR}/test_R2_small.fastq.gz"

    echo "OK: test_R1_small.fastq.gz, test_R2_small.fastq.gz"
    ls -lh "${TEST_DATA_DIR}/test_R1_small.fastq.gz" \
           "${TEST_DATA_DIR}/test_R2_small.fastq.gz"
fi

# ============================================================
# Step 5: Remove staged full-size raw reads
# ============================================================
echo ""
echo "--- Step 5: Removing staged raw reads ---"
rm -f "${TEST_DATA_DIR}/test_nanopore.fastq.gz" \
      "${TEST_DATA_DIR}/test_R1.fastq.gz" \
      "${TEST_DATA_DIR}/test_R2.fastq.gz"
echo "OK"

# ============================================================
# Summary
# ============================================================
echo ""
echo "============================================================"
echo "Done. Committed-ready test data in tests/data/:"
ls -lh "${TEST_DATA_DIR}/test_flye_assembly.fasta" \
       "${TEST_DATA_DIR}/test_flye_info.txt" \
       "${TEST_DATA_DIR}/test_unicycler_assembly.fasta" \
       "${TEST_DATA_DIR}/test_R1_small.fastq.gz" \
       "${TEST_DATA_DIR}/test_R2_small.fastq.gz" 2>/dev/null || true
echo ""
echo "Next steps:"
echo "  git add tests/data/test_flye_assembly.fasta \\"
echo "          tests/data/test_flye_info.txt \\"
echo "          tests/data/test_unicycler_assembly.fasta \\"
echo "          tests/data/test_R1_small.fastq.gz \\"
echo "          tests/data/test_R2_small.fastq.gz"
echo "  Source sample: ${SAMPLE_ID}"
echo "============================================================"
