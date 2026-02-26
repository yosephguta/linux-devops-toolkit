#!/usr/bin/env bash
set -euo pipefail

HOST="ec2-yoseph"
KEY="$HOME/devops/devops-key.pem"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tag>   e.g. $0 v3 or sha-abc123"
  exit 1
fi

TAG="$1"
IMAGE="fluffydabs/yoseph-site:${TAG}"
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Deploying ${IMAGE} to ${HOST}..."

REMOTE_OUTPUT=$(
ssh -i "$KEY" "$HOST" "bash -s" <<EOF
set -euo pipefail

IMAGE="$IMAGE"
NEXT_NAME="yoseph-site-next"
NEXT_PORT="8080"

echo "Pulling \$IMAGE..."
docker pull "\$IMAGE" >/dev/null

echo "Starting candidate container on :\$NEXT_PORT..."
docker rm -f "\$NEXT_NAME" >/dev/null 2>&1 || true
docker run -d --name "\$NEXT_NAME" -p "\$NEXT_PORT:80" "\$IMAGE" >/dev/null

echo "Health-checking candidate on localhost:\$NEXT_PORT..."
ok=0
for i in \$(seq 1 30); do
  if curl -fsS "http://localhost:\$NEXT_PORT" >/dev/null; then
    ok=1
    break
  fi
  sleep 0.2
done

if [ "\$ok" -ne 1 ]; then
  echo "ERROR: candidate failed health check"
  docker logs "\$NEXT_NAME" --tail 50 || true
  docker rm -f "\$NEXT_NAME" >/dev/null 2>&1 || true
  exit 1
fi

echo "Candidate healthy. Switching production container on :80..."
docker rm -f yoseph-site >/dev/null 2>&1 || true
docker run -d --restart unless-stopped --name yoseph-site -p 80:80 "\$IMAGE" >/dev/null

echo "Cleaning up candidate..."
docker rm -f "\$NEXT_NAME" >/dev/null 2>&1 || true

echo "Verifying production on localhost:80 (retrying to avoid transient socket reset)..."
ok=0
for i in \$(seq 1 30); do
  # don't use -f at first; nginx might not be ready for a split second
  if curl -sS http://localhost >/dev/null; then
    ok=1
    break
  fi
  sleep 0.2
done

if [ "\$ok" -ne 1 ]; then
  echo "ERROR: production did not become healthy"
  docker logs yoseph-site --tail 50 || true
  exit 1
fi

echo "--- docker ps ---"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo "--- labels ---"
docker inspect yoseph-site --format 'version={{ index .Config.Labels "org.opencontainers.image.version" }} revision={{ index .Config.Labels "org.opencontainers.image.revision" }} created={{ index .Config.Labels "org.opencontainers.image.created" }}'

echo "--- page head ---"
curl -s http://localhost | head -n 10

DIGEST=\$(docker inspect --format '{{ index .RepoDigests 0 }}' "\$IMAGE" 2>/dev/null || echo "unknown")
echo "DEPLOY_OK \$DIGEST"
EOF
)

echo "$REMOTE_OUTPUT"

if echo "$REMOTE_OUTPUT" | grep -q "^DEPLOY_OK "; then
  DIGEST=$(echo "$REMOTE_OUTPUT" | awk '/^DEPLOY_OK / {print $2}')
  echo "$DATE | $HOST | $IMAGE | $DIGEST" >> deploy/deploy-log.txt
  echo "Deployment recorded in deploy/deploy-log.txt"
else
  echo "Deployment failed — not logged."
  exit 1
fi