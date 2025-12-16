#!/bin/bash
# =============================================================================
# Build e Push da imagem AI Engine
# Uso: ./build.sh [version] [registry]
# Exemplo: ./build.sh 0.2.0 registry.3xf.app
# =============================================================================

set -e

VERSION=${1:-$(cat ../pyproject.toml | grep "version" | head -1 | cut -d'"' -f2)}
REGISTRY=${2:-registry.3xf.app}
IMAGE_NAME="ai-engine"

FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}"

echo "=========================================="
echo "Building AI Engine"
echo "Version: ${VERSION}"
echo "Registry: ${REGISTRY}"
echo "=========================================="

# Build da imagem
cd "$(dirname "$0")/.."

echo ">> Building image..."
docker build -t ${FULL_IMAGE}:${VERSION} -t ${FULL_IMAGE}:latest .

echo ">> Pushing to registry..."
docker push ${FULL_IMAGE}:${VERSION}
docker push ${FULL_IMAGE}:latest

echo "=========================================="
echo "Build complete!"
echo "Image: ${FULL_IMAGE}:${VERSION}"
echo ""
echo "To deploy:"
echo "  VERSION=${VERSION} docker stack deploy -c docker/swarm-stack.yml ai-engine"
echo "=========================================="
