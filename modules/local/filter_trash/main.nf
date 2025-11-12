process FILTER_TRASH {
    tag "${repeats.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '/home/jg2070/Desktop/dtol_review_August/CAP/nf-core-cap/nfcore-cap.sif' :
        'nfcore/cap:dev' }"

    input:
    tuple path(repeats), path(arrays)

    output:
    tuple path("${repeats.baseName}_filtered.csv"),
          path("${arrays.baseName}_filtered.csv"), emit: filtered
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    export WORKFLOW_DIR="${projectDir}"

    Rscript ${projectDir}/bin/filter_trash.R \\
        ${repeats} \\
        ${arrays} \\
        ${repeats.baseName}_filtered.csv \\
        ${arrays.baseName}_filtered.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    touch ${repeats.baseName}_filtered.csv
    touch ${arrays.baseName}_filtered.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
