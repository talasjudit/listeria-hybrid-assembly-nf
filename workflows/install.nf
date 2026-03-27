#!/usr/bin/env nextflow

/*
========================================================================================
    Container Installation Workflow
========================================================================================
    Downloads and verifies all Singularity containers for the hybrid assembly pipeline.
    Uses storeDir for automatic caching - already-downloaded containers are skipped.

    Usage: nextflow run main.nf -entry INSTALL -profile singularity -resume
========================================================================================
*/

nextflow.enable.dsl=2

// Container definitions: [filename, url, version_command, expected_version_string]
// version_command output is checked for expected_version_string - fails clearly if not found.
// BWA note: bwa exits 1 with no args and prints to stderr; pipe through grep to capture
// the version line cleanly without a non-zero exit code.

def containers = [
    // Illumina QC
    ['fastp-1.0.1.sif',         'oras://ghcr.io/talasjudit/bsup-2555/fastp:1.0.1-1',                                  'fastp --version',         '1.0.1'],

    // MultiQC reporting
    ['multiqc-1.31.sif',        'oras://ghcr.io/talasjudit/bsup-2555/multiqc:1.31-1',                                 'multiqc --version',       '1.31'],

    // Nanopore QC
    ['porechop_abi-0.5.1.sif',  'oras://ghcr.io/talasjudit/bsup-2555/porechop_abi:0.5.1-1',                           'porechop_abi --version',  '0.5.1'],
    ['filtlong-0.3.1.sif',      'oras://ghcr.io/talasjudit/bsup-2555/filtlong:0.3.1-1',                               'filtlong --version',      '0.3.1'],

    // Coverage + circularity check
    ['seqkit-2.12.0.sif',       'oras://ghcr.io/talasjudit/bsup-2555/seqkit:2.12.0-1',                                'seqkit version',          '2.12.0'],

    // Assembly
    ['flye-2.9.6.sif',          'oras://ghcr.io/talasjudit/bsup-2555/flye:2.9.6-1',                                   'flye --version',          '2.9.6'],
    ['unicycler-0.5.1.sif',     'docker://quay.io/biocontainers/unicycler:0.5.1--py39h746d604_5',                     'unicycler --version',     '0.5.1'],
    ['bwa-0.7.19.sif',          'docker://quay.io/biocontainers/bwa:0.7.19--h577a1d6_1',                              'bwa',                     '0.7.19'],
    ['polypolish_0.6.1.sif',    'docker://quay.io/biocontainers/polypolish:0.6.1--h3ab6199_0',                        'polypolish --version',    '0.6.1'],

    // Post-assembly processing
    ['dnaapler-1.3.0.sif',      'docker://quay.io/biocontainers/dnaapler:1.3.0--pyhdfd78af_0',                        'dnaapler --version',      '1.3.0'],
    ['mummer4-4.0.1.sif',       'docker://quay.io/biocontainers/mummer4:4.0.1--pl5321h9948957_0',                     'dnadiff --version',       '1.3'],

    // Assembly QC
    ['checkm2-1.1.0.sif',       'oras://ghcr.io/talasjudit/bsup-2555/checkm2:1.1.0-1',                               'checkm2 --version',       '1.1.0'],
    ['quast-5.3.0.sif',         'oras://ghcr.io/talasjudit/bsup-2555/quast:5.3.0-1',                                  'quast.py --version',      '5.3.0'],
]

/*
========================================================================================
    PROCESSES
========================================================================================
*/

process DOWNLOAD_CONTAINER {
    tag "$filename"
    storeDir params.singularity_cachedir

    input:
    tuple val(filename), val(url), val(version_cmd), val(expected_version)

    output:
    path filename

    script:
    """
    singularity pull ${filename} ${url}

    echo "Verifying ${filename}..."
    VERSION_OUTPUT=\$(singularity exec ./${filename} sh -c "${version_cmd}" 2>&1 | grep -v "^WARNING:" || true)
    echo "\${VERSION_OUTPUT}"

    if ! echo "\${VERSION_OUTPUT}" | grep -q "${expected_version}"; then
        echo "ERROR: Version verification failed for ${filename}"
        echo "Expected to find: ${expected_version}"
        echo "Got: \${VERSION_OUTPUT}"
        exit 1
    fi
    echo "OK: ${filename} contains expected version ${expected_version}"
    """
}

/*
========================================================================================
    WORKFLOW
========================================================================================
*/

workflow INSTALL {

    log.info """
    Container Installation Workflow
    ================================
    Cache directory : ${params.singularity_cachedir}
    Containers      : ${containers.size()}

    Already-downloaded containers are skipped automatically (storeDir).
    Use -resume if a previous run was interrupted.
    """.stripIndent()

    file(params.singularity_cachedir).mkdirs()

    ch_containers = Channel.fromList(
        containers.collect { item ->
            tuple(item[0], item[1], item[2], item[3])
        }
    )

    DOWNLOAD_CONTAINER(ch_containers)

    DOWNLOAD_CONTAINER.out
        .collect()
        .subscribe { files ->
            def lines = ["", "Installation complete. ${files.size()} containers verified:", ""]
            files.each { f ->
                def size  = f.size()
                def sizeStr = size > 1073741824 ? "${String.format('%.1f', size / 1073741824)} GB" :
                              size > 1048576    ? "${String.format('%.1f', size / 1048576)} MB" :
                                                  "${String.format('%.1f', size / 1024)} KB"
                lines << "  ${f.name.padRight(35)} ${sizeStr}"
            }
            lines << ""
            lines << "Next step: nextflow run main.nf -profile singularity,qib --input samplesheet.csv"
            lines << ""
            println lines.join('\n')
        }
}
