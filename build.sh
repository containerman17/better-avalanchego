#!/bin/bash

set -exuo pipefail

# Set up QEMU for multi-architecture builds
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Set up buildx builder
docker buildx create --name mybuilder --use || true
docker buildx inspect mybuilder --bootstrap

# Architectures
ARCHITECTURES=("amd64" "arm64")

# Add specific versions
AVALANCHEGO_VERSIONS+=("1.12.0" "1.12.1")
SUBNETEVM_VERSIONS+=("0.7.0")

# Pull AvalancheGo images first
for avalanche_version in "${AVALANCHEGO_VERSIONS[@]}"; do
  echo "Pulling AvalancheGo ${avalanche_version}"
  docker pull "avaplatform/avalanchego:v${avalanche_version}"
done

# Modified build process using buildx
for avalanche_version in "${AVALANCHEGO_VERSIONS[@]}"; do
  for subnet_version in "${SUBNETEVM_VERSIONS[@]}"; do
    echo "Building for AvalancheGo ${avalanche_version} and Subnet-EVM ${subnet_version}"
    
    # Create manifest list name
    MANIFEST="containerman17/easy-avalanchego:v${avalanche_version}_v${subnet_version}"
    
    # Build and push all architectures in one command
    docker buildx build \
      --platform linux/amd64,linux/arm64 \
      --build-arg AVALANCHEGO_VERSION="${avalanche_version}" \
      --build-arg SUBNETEVM_VERSION="${subnet_version}" \
      -t "${MANIFEST}" \
      --push \
      . || exit 1  # Add error checking
  done
done

