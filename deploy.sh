#!/bin/bash
IMAGE="${IMAGE:-ghcr.io/madesh94/devops-app:17829006d1583048e3f86f4a82b220853235e366}"
CONTAINER="devops-app-production"
OLD_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER" 2>/dev/null || true)


if ! docker pull "$IMAGE"; then
    echo "ERROR: Unable to pull new Docker image."
    echo "Existing production container will remain untouched."
    exit 1
fi

docker stop "$CONTAINER" 2>/dev/null || true

docker rm "$CONTAINER" 2>/dev/null || true

if [ "${ROLLBACK_TEST:-false}" = "true" ]; then
    echo "ROLLBACK TEST: Starting new version with simulated failure"
    docker run -d -e SIMULATE_FAILURE=true \
        -p 8083:8080 --name "$CONTAINER" "$IMAGE"
    RUN_STATUS=$?
else
    docker run -d -p 8083:8080 --name "$CONTAINER" "$IMAGE"
    RUN_STATUS=$?
fi

if [ "$RUN_STATUS" -ne 0 ]; then
    echo "ERROR: New container failed to start."
    echo "Proceeding to deployment failure handling."
fi

if [ "$RUN_STATUS" -eq 0 ]; then
    for i in {1..10}; do
        RUNNING=$(docker inspect --format='{{.State.Running}}' "$CONTAINER" 2>/dev/null || true)

        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time 2 http://localhost:8083 || true)

        if [ "$RUNNING" = "true" ] && [ "$HTTP_CODE" = "200" ]; then
            echo "Application is healthy"
            exit 0
        fi

        echo "Waiting for application..."
        sleep 1
     done
fi

echo "Application failed health check"
echo "Rolling back to previous version..."

docker rm -f "$CONTAINER" 2>/dev/null || true

if [ -n "${OLD_IMAGE}" ]; then
    docker run -d -p 8083:8080 --name "$CONTAINER" "${OLD_IMAGE}"

for i in {1..10}; do
    RUNNING=$(docker inspect --format='{{.State.Running}}' "$CONTAINER" 2>/dev/null || true)

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 2 http://localhost:8083 || true)

        RESTORED_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER" 2>/dev/null || true)

    if [ "$RUNNING" = "true" ] && \
       [ "$HTTP_CODE" = "200" ] && \
       [ "$RESTORED_IMAGE" = "$OLD_IMAGE" ]; then
        echo "Rollback completed successfully"
        echo "Restored image: $RESTORED_IMAGE"
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
