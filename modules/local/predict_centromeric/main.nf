process PREDICT_CENTROMERIC {
    tag "${scores.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '/home/jg2070/Desktop/dtol_review_August/CAP/nf-core-cap/nfcore-cap.sif' :
        'nfcore/cap:dev' }"

    input:
    path scores

    output:
    path "${scores.baseName}_predictions.csv", emit: predictions
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    python3 ${projectDir}/bin/predict_centromeric.py \\
        ${scores} \\
        ${projectDir}/model/centromeric_model_v2.pkl \\
        ${scores.baseName}_predictions.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
        scikit-learn: \$(python3 -c "import sklearn; print(sklearn.__version__)")
        xgboost: \$(python3 -c "import xgboost; print(xgboost.__version__)")
    END_VERSIONS
    """

    stub:
    """
    touch ${scores.baseName}_predictions.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """
}
