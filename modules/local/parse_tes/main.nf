process PARSE_TES {
    tag "${te_gff.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jacgonisa/nfcore-cap:latest' :
        'jacgonisa/nfcore-cap:latest' }"

    input:
    path te_gff

    output:
    path "${te_gff.baseName}_TEs_parsed.csv", emit: parsed
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    export WORKFLOW_DIR="${projectDir}"

    Rscript ${projectDir}/bin/parse_TEs.R \\
        ${te_gff} \\
        ${te_gff.baseName}_TEs_parsed.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    touch ${te_gff.baseName}_TEs_parsed.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
