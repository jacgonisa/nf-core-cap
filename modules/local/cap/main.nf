process CAP {
    tag "${assembly.baseName}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '/home/jg2070/Desktop/dtol_review_August/CAP/nf-core-cap/nfcore-cap.sif' :
        'nfcore/cap:dev' }"

    input:
    path assembly
    path predictions
    tuple path(repeats_r), path(arrays_r), path(genome_classes)
    path metadata
    val te_f
    val gene_f
    path gc_ch
    path ctw_ch
    path scores

    output:
    path "${prefix}_CAP_plot_*.png"             , emit: plot
    path "${prefix}_CAP_dotplot.png"            , emit: dotplot
    path "${prefix}_CAP_repeat_families.csv"    , emit: repeat_families
    path "${prefix}_CAP_model.txt"              , emit: model
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    export WORKFLOW_DIR="${projectDir}"

    Rscript ${projectDir}/bin/CAP.R \\
        ${predictions} \\
        ${repeats_r} \\
        ${arrays_r} \\
        ${genome_classes} \\
        ${metadata} \\
        ${prefix} \\
        ${gc_ch} \\
        ${ctw_ch} \\
        ${te_f} \\
        ${gene_f} \\
        ${scores} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${assembly.baseName}"
    """
    touch ${prefix}_CAP_plot_1.png
    touch ${prefix}_CAP_dotplot.png
    touch ${prefix}_CAP_repeat_families.csv
    touch ${prefix}_CAP_model.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
