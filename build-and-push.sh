#!/bin/bash

set -e

# Configuration
GHCR_USERNAME="${GHCR_USERNAME:-ayewo}"
IMAGE_NAME="${IMAGE_NAME:-tt-ssh}"
IMAGE_TAG="${IMAGE_TAG:-latest}"


# `/root/tt/tt-metal` contains compiled binaries on a running Koyeb instance
cd /root/tt
tar -czf tt-metal.tar.gz tt-metal/

# Move the TAR to /tmp
mv /root/tt/tt-metal.tar.gz /tmp

# The compressed TAR weighs in at 3.1G
du -shL /tmp/tt-metal.tar.gz 

# Copy `tt-metal.tar.gz` into the Docker context
mkdir -p ~/docker && cd ~/docker
git clone https://github.com/ayewo/tt-ssh .

# Copy the TAR to ~/docker/tars/
mkdir -p ~/docker/tars && cp /tmp/tt-metal.tar.gz ~/docker/tars/

# Build and push to GHCR.io
echo $GITHUB_TOKEN | docker login ghcr.io -u ayewo --password-stdin
docker buildx build -t ghcr.io/ayewo/$IMAGE_NAME:$IMAGE_TAG .
docker push ghcr.io/ayewo/$IMAGE_NAME:$IMAGE_TAG

# Clean up
rm -rf /tmp/tt-metal.tar.gz ~/docker/tars/tt-metal.tar.gz
