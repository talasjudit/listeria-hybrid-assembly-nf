/*
========================================================================================
    UNICYCLER_WITH_FLYE - Hybrid Assembly Using Existing Flye Assembly
========================================================================================
    Unicycler assembles bacterial genomes using both short and long reads

    This is the HYBRID WITH EXISTING ASSEMBLY mode:
    - Takes Illumina short reads, Nanopore long reads, AND an existing Flye assembly
    - Uses the Flye assembly as a scaffold
    - Polishes and corrects the long-read assembly using short reads
    - Generally produces higher quality assemblies than standard mode

    For standard hybrid assembly WITHOUT Flye, see: unicycler.nf

    Container: docker://quay.io/biocontainers/unicycler:0.5.1--py39h746d604_5
    Documentation: https://github.com/rrwick/Unicycler

    TODO: Implement unicycler command in Phase 2+
========================================================================================
*/

process UNICYCLER_WITH_FLYE {
    tag "$meta.id"

    container "${params.singularity_cachedir}/unicycler-0.5.1.sif"

    input:
    tuple val(meta), path(illumina_reads), path(nanopore_reads), path(flye_assembly)
    // illumina_reads = [R1_trimmed.fastq.gz, R2_trimmed.fastq.gz]
    // nanopore_reads = nanopore_filtlong.fastq.gz
    // flye_assembly = flye_assembly.fasta

    output:
    tuple val(meta), path('*_unicycler.fasta'), emit: assembly
    tuple val(meta), path('*/assembly.gfa')   , emit: gfa
    tuple val(meta), path('*.log')            , emit: log
    path 'versions.yml'                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO Phase 2: Implement unicycler command (WITH EXISTING ASSEMBLY MODE)
    // Expected inputs:
    //   - illumina_reads[0] = R1_trimmed.fastq.gz (Illumina forward reads)
    //   - illumina_reads[1] = R2_trimmed.fastq.gz (Illumina reverse reads)
    //   - nanopore_reads = nanopore_filtlong.fastq.gz (Nanopore long reads)
    //   - flye_assembly = flye_assembly.fasta (existing Flye assembly)
    //
    // Expected outputs:
    //   - ${prefix}_unicycler.fasta (final assembly)
    //   - ${prefix}_unicycler/assembly.gfa (assembly graph)
    //   - ${prefix}_unicycler.log (assembly log)
    //
    // Key parameters to include:
    //   -1 ${illumina_reads[0]} : Illumina forward reads
    //   -2 ${illumina_reads[1]} : Illumina reverse reads
    //   -l ${nanopore_reads} : Long reads (Nanopore)
    //   --existing_long_read_assembly ${flye_assembly} : Use existing Flye assembly
    //   -o ${prefix}_unicycler : Output directory
    //   -t ${task.cpus} : Use allocated CPUs
    //   ${args} : Additional user-specified arguments
    //
    // Additional options to consider:
    //   --mode normal : Assembly mode (conservative/normal/bold)
    //   --min_fasta_length 500 : Minimum contig length to output
    //   --keep 0 : Level of file retention (0=only final, 3=keep everything)
    //
    // Post-processing:
    //   Copy assembly.fasta to ${prefix}_unicycler.fasta for standardized naming
    //   Unicycler creates output directory with multiple files
    //
    // Log capture:
    //   Redirect stdout/stderr to ${prefix}_unicycler.log
    //
    // IMPORTANT: This mode uses --existing_long_read_assembly flag
    //            This is what differentiates it from standard UNICYCLER process

    """
    # TODO: Implement unicycler command here (WITH EXISTING ASSEMBLY MODE)

    echo "TODO: Run unicycler in HYBRID WITH EXISTING ASSEMBLY mode"
    echo "TODO: Illumina R1: ${illumina_reads[0]}"
    echo "TODO: Illumina R2: ${illumina_reads[1]}"
    echo "TODO: Nanopore: ${nanopore_reads}"
    echo "TODO: Existing assembly: ${flye_assembly}"
    echo "TODO: Output assembly to ${prefix}_unicycler directory"
    echo "TODO: Copy final assembly to ${prefix}_unicycler.fasta"
    echo "TODO: Save log to ${prefix}_unicycler.log"

    # Placeholder commands - remove this in Phase 2
    mkdir -p ${prefix}_unicycler
    touch ${prefix}_unicycler.fasta
    touch ${prefix}_unicycler/assembly.gfa
    touch ${prefix}_unicycler.log

    # Version capture - TODO: Update with actual unicycler version command
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        unicycler: \$(unicycler --version 2>&1 | sed 's/Unicycler v//g' || echo "version_unavailable")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_unicycler
    touch ${prefix}_unicycler.fasta
    touch ${prefix}_unicycler/assembly.gfa
    touch ${prefix}_unicycler.log
    touch versions.yml
    """
}
