# Dockerfile for nf-core/cap
FROM mambaorg/micromamba:1.5-bullseye

# Set labels for nf-core
LABEL authors="Your Name" \
      description="Docker image for nf-core/cap pipeline" \
      maintainer="your.email@example.com"

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    libblas-dev \
    liblapack-dev \
    zlib1g-dev \
    libicu-dev \
    git \
    bash \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Conda environment
COPY environment.yml /tmp/environment.yml
RUN micromamba create -y -n cap -f /tmp/environment.yml && \
    micromamba clean --all --yes

# Activate environment and install any R packages not available via Conda
RUN micromamba run -n cap Rscript -e "\
    if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes', repos='https://cloud.r-project.org'); \
    install.packages('BCT', repos='https://cloud.r-project.org')"
# Activate conda environment
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENV MAMBA_DOCKERFILE_ACTIVATE=1
ENV PATH="/opt/conda/envs/cap/bin:$PATH"

# Note: bin/, model/, and TRASH_2/ are accessed via ${projectDir} mount by Nextflow
# No need to copy them into the container

# Set working directory
WORKDIR /work

# Default command
CMD ["/bin/bash"]
