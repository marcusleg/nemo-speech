#!/usr/bin/env bash
# Starts the image, waits for the server to report ready, and checks that it
# lists the baked-in ASR model. Usage: scripts/smoke-test-image.sh IMAGE
set -euo pipefail

image=${1:?usage: $0 IMAGE}
engine=${CONTAINER_ENGINE:-docker}
name=nemo-speech-smoke-test-$$

cleanup() {
    "$engine" logs "$name" 2>&1 | tail -n 20 || true
    "$engine" rm -f "$name" >/dev/null 2>&1 || true
}
trap cleanup EXIT

"$engine" run --detach --name "$name" --publish 127.0.0.1:18080:8080 "$image" >/dev/null

for _ in $(seq 1 60); do
    if curl -fsS http://127.0.0.1:18080/ready >/dev/null 2>&1; then
        break
    fi
    sleep 2
done
curl -fsS http://127.0.0.1:18080/ready
echo
curl -fsS http://127.0.0.1:18080/v1/models | tee /dev/stderr | grep -q nemotron
echo
echo "smoke test passed"
