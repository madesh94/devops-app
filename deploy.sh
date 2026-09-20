#!/bin/bash
IMAGE="${IMAGE:-ghcr.io/madesh94/devops-app:17829006d1583048e3f86f4a82b220853235e366}"
CONTAINER="devops-app-production"


docker pull "$IMAGE"
docker stop "$CONTAINER" 2>/dev/null || true
docker rm "$CONTAINER" 2>/dev/null || true
docker run -d -p 8083:8080 --name "$CONTAINER" "$IMAGE"
for i in {1..10}; do
    if curl -s http://localhost:8083; then
        exit 0
    fi
    sleep 1
done

exit 1
