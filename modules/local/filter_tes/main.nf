process FILTER_TES {
    tag "${parsed.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '/home/jg2070/Desktop/dtol_review_August/CAP/nf-core-cap/nfcore-cap.sif' :
        'nfcore/cap:dev' }"

    input:
    path parsed

    output:
    path "${parsed.baseName}_filtered.csv", emit: filtered
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    export WORKFLOW_DIR="${projectDir}"

    Rscript ${projectDir}/bin/filter_TEs.R \\
        ${parsed} \\
        ${parsed.baseName}_filtered.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    touch ${parsed.baseName}_filtered.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
