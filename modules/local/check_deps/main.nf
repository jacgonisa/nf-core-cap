process CHECK_DEPS {
    tag "check nhmmer and mafft availability"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '/home/jg2070/Desktop/dtol_review_August/CAP/nf-core-cap/nfcore-cap.sif' :
        'nfcore/cap:dev' }"

    output:
    val true           , emit: ready
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    echo "Checking for nhmmer:"
    if ! command -v nhmmer &> /dev/null; then
        echo "❌ nhmmer not found in PATH"
        exit 1
    else
        nhmmer -h 2>&1 | head -n 3 || true
    fi

    echo "Checking for mafft:"
    if ! command -v mafft &> /dev/null; then
        echo "❌ mafft not found in PATH"
        exit 1
    else
        mafft --version 2>&1 || true
    fi

    echo "✅ All dependencies found."

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hmmer: \$(nhmmer -h | grep "^# HMMER" | sed 's/# HMMER //; s/ .*//')
        mafft: \$(mafft --version 2>&1 | head -n1 | sed 's/v//')
    END_VERSIONS
    """
}
