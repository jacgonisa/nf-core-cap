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

# Activate conda environment
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENV MAMBA_DOCKERFILE_ACTIVATE=1
ENV PATH="/opt/conda/envs/cap/bin:$PATH"

# Copy pipeline scripts and model
COPY bin/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.R /usr/local/bin/*.py

COPY model/ /model/

# Set working directory
WORKDIR /work

# Default command
CMD ["/bin/bash"]
