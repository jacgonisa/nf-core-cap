#!/bin/bash
# Script to build Docker and Singularity containers for nf-core/cap

set -e

DOCKER_TAG="nfcore/cap:dev"
SINGULARITY_IMAGE="nfcore-cap-dev.img"

echo "Building Docker image..."
docker build -t ${DOCKER_TAG} .

echo "Docker image built successfully: ${DOCKER_TAG}"
echo ""

# Option 1: Convert Docker to Singularity locally
if command -v singularity &> /dev/null; then
    echo "Converting Docker image to Singularity..."
    singularity build ${SINGULARITY_IMAGE} docker-daemon://${DOCKER_TAG}
    echo "Singularity image created: ${SINGULARITY_IMAGE}"
else
    echo "Singularity not found. To convert manually:"
    echo "  singularity build ${SINGULARITY_IMAGE} docker-daemon://${DOCKER_TAG}"
fi

echo ""
echo "To use with Nextflow:"
echo "  -profile docker"
echo "  or"
echo "  -profile singularity"
