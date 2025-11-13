process CTW {
    tag "${assembly.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jacgonisa/nfcore-cap:latest' :
        'jacgonisa/nfcore-cap:latest' }"

    input:
    path assembly

    output:
    path "${prefix}_CTW.csv", emit: ctw
    path "versions.yml"      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    export WORKFLOW_DIR="${projectDir}"

    Rscript ${projectDir}/bin/CTW.R \\
        ${assembly} \\
        ${prefix}_CTW.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    touch ${prefix}_CTW.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
