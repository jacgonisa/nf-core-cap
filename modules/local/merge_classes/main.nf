process MERGE_CLASSES {
    tag "${repeats_f.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jacgonisa/nfcore-cap:latest' :
        'jacgonisa/nfcore-cap:latest' }"

    input:
    tuple path(repeats_f), path(arrays_f)

    output:
    tuple path("${repeats_f.baseName}_reclassed.csv"),
          path("${arrays_f.baseName}_reclassed.csv"),
          path("${repeats_f.baseName}_genome_classes.csv"), emit: reclassed
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    export WORKFLOW_DIR="${projectDir}"

    Rscript ${projectDir}/bin/merge_classes.R \\
        ${repeats_f} \\
        ${arrays_f} \\
        ${repeats_f.baseName}_reclassed.csv \\
        ${arrays_f.baseName}_reclassed.csv \\
        ${repeats_f.baseName}_genome_classes.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    touch ${repeats_f.baseName}_reclassed.csv
    touch ${arrays_f.baseName}_reclassed.csv
    touch ${repeats_f.baseName}_genome_classes.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
