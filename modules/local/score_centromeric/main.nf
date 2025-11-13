process SCORE_CENTROMERIC {
    tag "${assembly.baseName}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jacgonisa/nfcore-cap:latest' :
        'jacgonisa/nfcore-cap:latest' }"

    input:
    path assembly
    tuple path(repeats_r), path(arrays_r), path(genome_classes)
    path metadata
    val te_f
    val gene_f

    output:
    path "${prefix}_centromeric_scores.csv", emit: scores
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    export WORKFLOW_DIR="${projectDir}"

    Rscript ${projectDir}/bin/score_centromeric_classes.R \\
        ${repeats_r} \\
        ${arrays_r} \\
        ${genome_classes} \\
        ${metadata} \\
        ${te_f} \\
        ${gene_f} \\
        ${prefix}_centromeric_scores.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    touch ${prefix}_centromeric_scores.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
