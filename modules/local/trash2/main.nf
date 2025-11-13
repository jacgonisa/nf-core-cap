process TRASH2 {
    tag "TRASH2 on ${assembly.baseName}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jacgonisa/nfcore-cap:latest' :
        'jacgonisa/nfcore-cap:latest' }"

    input:
    tuple path(assembly), val(templates)
    val ready

    output:
    tuple path("${assembly.name}_repeats_with_seq.csv"),
          path("${assembly.name}_arrays.csv"), emit: trash_results
    path "versions.yml"                    , emit: versions

    when:
    ready && task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def t = templates ? "-t ${templates}" : ''
    def prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    echo "Running TRASH2 with output dir: \$PWD"
    Rscript ${projectDir}/modules/TRASH_2/src/TRASH.R \\
        -f ${assembly} \\
        -o \$PWD \\
        --cores_no ${task.cpus} \\
        --max_rep_size ${params.max_rep_size} \\
        ${t} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trash2: \$(echo "2.0")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    touch ${assembly.name}_repeats_with_seq.csv
    touch ${assembly.name}_arrays.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trash2: \$(echo "2.0")
    END_VERSIONS
    """
}
