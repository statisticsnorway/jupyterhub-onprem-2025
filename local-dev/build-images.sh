#!/usr/bin/env bash
# Build the Hub, JupyterLab, and RStudio images from this repository
# (same Dockerfiles and build-args as CI). Tag them *:local for local-dev/.env.
set -euo pipefail

ONLY="${1:-all}"
case "$ONLY" in
  all|hub|lab|rstudio) ;;
  *)
    echo "Usage: $0 [all|hub|lab|rstudio]" >&2
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PYTHON_VERSION="313"
ARROW_VERSION="24.0.0"
JAVA_VERSION="17"
CRAN_DISTRO="noble"

repo_build() {
  local tag="$1" file="$2" context="$3"
  shift 3
  echo
  echo "=== Building $tag ==="
  docker build -t "$tag" -f "$file" "$@" "$context"
}

if [[ "$ONLY" == "all" || "$ONLY" == "hub" ]]; then
  repo_build onprem-jupyterhub:local \
    docker/jupyterhub/Dockerfile.hub \
    docker/jupyterhub
fi

if [[ "$ONLY" == "all" || "$ONLY" == "lab" ]]; then
  repo_build onprem-jupyterlab-r440:local \
    docker/jupyterhub/Dockerfile.lab \
    docker/jupyterhub \
    --build-arg R_VERSION=4.4.0 \
    --build-arg PYTHON_VERSION="$PYTHON_VERSION" \
    --build-arg ARROW_VERSION="$ARROW_VERSION" \
    --build-arg JAVA_VERSION="$JAVA_VERSION" \
    --build-arg CRAN_DISTRO="$CRAN_DISTRO"
  repo_build onprem-jupyterlab-r460:local \
    docker/jupyterhub/Dockerfile.lab \
    docker/jupyterhub \
    --build-arg R_VERSION=4.6.0 \
    --build-arg PYTHON_VERSION="$PYTHON_VERSION" \
    --build-arg ARROW_VERSION="$ARROW_VERSION" \
    --build-arg JAVA_VERSION="$JAVA_VERSION" \
    --build-arg CRAN_DISTRO="$CRAN_DISTRO"
fi

if [[ "$ONLY" == "all" || "$ONLY" == "rstudio" ]]; then
  repo_build onprem-rstudio-r440:local \
    docker/rstudio/Dockerfile \
    docker/rstudio \
    --build-arg R_VERSION=4.4.0 \
    --build-arg ARROW_VERSION="$ARROW_VERSION" \
    --build-arg JAVA_VERSION="$JAVA_VERSION" \
    --build-arg CRAN_DISTRO="$CRAN_DISTRO"
  repo_build onprem-rstudio-r460:local \
    docker/rstudio/Dockerfile \
    docker/rstudio \
    --build-arg R_VERSION=4.6.0 \
    --build-arg ARROW_VERSION="$ARROW_VERSION" \
    --build-arg JAVA_VERSION="$JAVA_VERSION" \
    --build-arg CRAN_DISTRO="$CRAN_DISTRO"
fi

echo
echo "Done. Start Hub with: ./local-dev/up.sh"
