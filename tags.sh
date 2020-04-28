#!/usr/bin/env bash
set -euo pipefail

# Tags used for builds
LATEST_PREVIEW="6.0pre7"
LATEST_STABLE="5.6.1"

BUILDER="docker"
if command -v podman >/dev/null; then
  BUILDER="podman"
fi

VERSIONS=("$LATEST_STABLE" "$LATEST_PREVIEW")
NAME="${DOCKER_REPO:-roht/omnetpp}"

export BUILDER
export VERSIONS
export NAME

