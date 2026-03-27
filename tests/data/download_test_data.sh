#!/usr/bin/env bash
# =============================================================================
# Download test FASTQ files for pipeline testing
# =============================================================================
# Downloads raw reads for test sample BL07-034 (Listeria monocytogenes 07/034)
# from ENA (BioProject PRJNA837734).
#
# ENA accessions:
#   SRR19184179  Nanopore (MinION, ~200 Mb)
#   SRR19184062  Illumina (NextSeq 500 paired-end, ~185 Mb)
#
# Requires: wget on PATH
# Note: run from a login node or machine with internet access.
#
# Usage:
#   bash tests/data/download_test_data.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NANOPORE_URL="http://ftp.sra.ebi.ac.uk/vol1/fastq/SRR191/079/SRR19184179/SRR19184179_1.fastq.gz"
ILLUMINA_R1_URL="http://ftp.sra.ebi.ac.uk/vol1/fastq/SRR191/062/SRR19184062/SRR19184062_1.fastq.gz"
ILLUMINA_R2_URL="http://ftp.sra.ebi.ac.uk/vol1/fastq/SRR191/062/SRR19184062/SRR19184062_2.fastq.gz"

if ! command -v wget &>/dev/null; then
    echo "ERROR: wget not found. Install wget and add it to PATH."
    exit 1
fi

echo "Downloading test data from ENA (BioProject PRJNA837734)..."
echo "Sample: Listeria monocytogenes BL07-034 (07/034)"
echo ""

# Nanopore reads
if [ -f "${SCRIPT_DIR}/test_nanopore.fastq.gz" ]; then
    echo "Already present: test_nanopore.fastq.gz - skipping"
else
    echo "Downloading: SRR19184179 (Nanopore)"
    wget -q --show-progress -O "${SCRIPT_DIR}/test_nanopore.fastq.gz" "${NANOPORE_URL}"
    echo "OK: test_nanopore.fastq.gz"
fi

# Illumina paired-end reads
if [ -f "${SCRIPT_DIR}/test_R1.fastq.gz" ] && [ -f "${SCRIPT_DIR}/test_R2.fastq.gz" ]; then
    echo "Already present: test_R1.fastq.gz, test_R2.fastq.gz - skipping"
else
    echo "Downloading: SRR19184062 (Illumina R1)"
    wget -q --show-progress -O "${SCRIPT_DIR}/test_R1.fastq.gz" "${ILLUMINA_R1_URL}"
    echo "Downloading: SRR19184062 (Illumina R2)"
    wget -q --show-progress -O "${SCRIPT_DIR}/test_R2.fastq.gz" "${ILLUMINA_R2_URL}"
    echo "OK: test_R1.fastq.gz, test_R2.fastq.gz"
fi

echo ""
echo "Done. Test data is ready in: ${SCRIPT_DIR}"
