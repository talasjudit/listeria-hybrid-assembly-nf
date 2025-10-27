/*
========================================================================================
    FLYE - Long-Read De Novo Assembly
========================================================================================
    Flye is a de novo assembler for single-molecule sequencing reads (Nanopore/PacBio)

    Key features:
    - High-quality long-read assembly
    - Repeat resolution
    - Can be used to scaffold Unicycler hybrid assemblies
    - Produces assembly graph and detailed statistics

    Container: oras://ghcr.io/talasjudit/bsup-2555/flye:2.9.6-1
    Documentation: https://github.com/fenderglass/Flye

    TODO: Implement flye command in Phase 2+
========================================================================================
*/

process FLYE {
    tag "$meta.id"

    container "${params.singularity_cachedir}/flye-2.9.6.sif"

    input:
    tuple val(meta), path(reads)  // reads = nanopore_filtlong.fastq.gz

    output:
    tuple val(meta), path('*_flye.fasta'), emit: assembly
    tuple val(meta), path('*/assembly_info.txt'), emit: info
    tuple val(meta), path('*.log')       , emit: log
    path 'versions.yml'                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO Phase 2: Implement flye command
    // Expected input:
    //   - reads = nanopore_filtlong.fastq.gz (filtered Nanopore reads)
    //
    // Expected outputs:
    //   - ${prefix}_flye.fasta (final assembly)
    //   - ${prefix}_flye/assembly_info.txt (contig information)
    //   - ${prefix}_flye.log (assembly log)
    //
    // Key parameters to include:
    //   --nano-hq : High-quality Nanopore reads (Q20+)
    //     Alternative: --nano-raw for older/lower quality Nanopore data
    //   --out-dir ${prefix}_flye : Output directory
    //   --threads ${task.cpus} : Use allocated CPUs
    //   --genome-size ${params.genome_size} : Expected genome size (e.g., '3m')
    //   ${args} : Additional user-specified arguments
    //
    // Additional options to consider:
    //   --iterations 2 : Number of polishing iterations (default: 1)
    //   --min-overlap : Minimum overlap between reads
    //   --meta : Enable metagenomic mode (if applicable)
    //
    // Post-processing:
    //   Copy assembly.fasta to ${prefix}_flye.fasta for standardized naming
    //   Flye creates output directory with multiple files
    //
    // Log capture:
    //   Redirect stdout/stderr to ${prefix}_flye.log

    """
    # TODO: Implement flye command here

    echo "TODO: Run flye on ${reads}"
    echo "TODO: Use genome size: ${params.genome_size}"
    echo "TODO: Output assembly to ${prefix}_flye directory"
    echo "TODO: Copy final assembly to ${prefix}_flye.fasta"
    echo "TODO: Save log to ${prefix}_flye.log"

    # Placeholder commands - remove this in Phase 2
    mkdir -p ${prefix}_flye
    touch ${prefix}_flye.fasta
    touch ${prefix}_flye/assembly_info.txt
    touch ${prefix}_flye.log

    # Version capture - TODO: Update with actual flye version command
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$(flye --version 2>&1 | sed 's/Flye //g' || echo "version_unavailable")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_flye
    touch ${prefix}_flye.fasta
    touch ${prefix}_flye/assembly_info.txt
    touch ${prefix}_flye.log
    touch versions.yml
    """
}
