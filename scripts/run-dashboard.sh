#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-ghcr.io/rdone4425/openclaw-bot-review:main}"
CONTAINER_NAME="${CONTAINER_NAME:-openclaw-dashboard}"
HOST_PORT="${HOST_PORT:-3000}"
OPENCLAW_HOME="${OPENCLAW_HOME:-/root/.openclaw}" # host path
OPENCLAW_READONLY="${OPENCLAW_READONLY:-0}"

CONTAINER_OPENCLAW_HOME="/openclaw"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Install Docker first." >&2
  exit 1
fi

if [[ ! -f "${OPENCLAW_HOME}/openclaw.json" ]]; then
  echo "Missing: ${OPENCLAW_HOME}/openclaw.json" >&2
  echo "Set OPENCLAW_HOME to the host directory that contains openclaw.json." >&2
  exit 1
fi

echo "Pulling image: ${IMAGE}"
docker pull "${IMAGE}"

echo "Removing existing container (if any): ${CONTAINER_NAME}"
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

volume="${OPENCLAW_HOME}:${CONTAINER_OPENCLAW_HOME}"
if [[ "${OPENCLAW_READONLY}" == "1" ]]; then
  volume="${volume}:ro"
fi

echo "Starting container: ${CONTAINER_NAME}"
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p "${HOST_PORT}:3000" \
  -e "OPENCLAW_HOME=${CONTAINER_OPENCLAW_HOME}" \
  -v "${volume}" \
  "${IMAGE}" >/dev/null

echo "OK"
echo "URL: http://localhost:${HOST_PORT}"
echo "Logs: docker logs -f ${CONTAINER_NAME}"

