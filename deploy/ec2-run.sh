#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-v1}"
IMAGE="fluffydabs/yoseph-site:${TAG}"

docker pull "$IMAGE"
docker rm -f yoseph-site >/dev/null 2>&1 || true
docker run -d --restart unless-stopped --name yoseph-site -p 80:80 "$IMAGE"

echo "Deployed: $IMAGE"
curl -s localhost | head -n 5