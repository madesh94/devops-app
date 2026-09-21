#!/bin/bash
IMAGE="${IMAGE:-ghcr.io/madesh94/devops-app:17829006d1583048e3f86f4a82b220853235e366}"
CONTAINER="devops-app-production"
OLD_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER" 2>/dev/null || true)


docker pull "$IMAGE"

docker stop "$CONTAINER" 2>/dev/null || true

docker rm "$CONTAINER" 2>/dev/null || true

docker run -d -p 8083:8080 --name "$CONTAINER" "$IMAGE"

for i in {1..10}; do
    if [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8083)" = "200" ]; then
        echo "Application is healthy"
        exit 0
    fi

    echo "Waiting for application..."
    sleep 1
done

echo "Application failed health check"
echo "Rolling back to previous version..."

docker rm -f "$CONTAINER" 2>/dev/null || true

if [ -n "${OLD_IMAGE}" ]; then
    docker run -d -p 8083:8080 --name "$CONTAINER" "${OLD_IMAGE}"

for i in {1..10}; do
    if [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8083)" = "200" ]; then
        echo "Rollback completed successfully"
            exit 1
    fi

    echo "Waiting for rollback..."
    sleep 1
done

    echo "Rollback failed"
    exit 1
else
    echo "No previous image found. Rollback not possible."
    exit 1
fi
