process GC {
    tag "${assembly.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '/home/jg2070/Desktop/dtol_review_August/CAP/nf-core-cap/nfcore-cap.sif' :
        'nfcore/cap:dev' }"

    input:
    path assembly

    output:
    path "${prefix}_GC.csv", emit: gc
    path "versions.yml"     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    export WORKFLOW_DIR="${projectDir}"

    Rscript ${projectDir}/bin/GC.R \\
        ${assembly} \\
        ${prefix}_GC.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    touch ${prefix}_GC.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
