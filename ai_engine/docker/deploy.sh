#!/bin/bash
# =============================================================================
# Deploy AI Engine no Docker Swarm
# Uso: ./deploy.sh [version]
# =============================================================================

set -e

VERSION=${1:-latest}
STACK_NAME="ai-engine"

echo "=========================================="
echo "Deploying AI Engine Stack"
echo "Version: ${VERSION}"
echo "Stack: ${STACK_NAME}"
echo "=========================================="

# Deploy
cd "$(dirname "$0")"
export VERSION=${VERSION}

echo ">> Deploying stack..."
docker stack deploy -c swarm-stack.yml ${STACK_NAME}

echo ">> Waiting for services..."
sleep 5

echo ">> Service status:"
docker stack services ${STACK_NAME}

echo "=========================================="
echo "Deploy complete!"
echo ""
echo "Check logs:"
echo "  docker service logs ${STACK_NAME}_gateway -f"
echo "  docker service logs ${STACK_NAME}_worker -f"
echo ""
echo "Scale workers:"
echo "  docker service scale ${STACK_NAME}_worker=4"
echo "=========================================="