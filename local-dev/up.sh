#!/usr/bin/env bash
# Start the local JupyterHub stack against images tagged *:local.
# Build those images first with ./local-dev/build-images.sh
# (or pass --stub to test Hub UI only, without the real Lab/RStudio images).
set -euo pipefail

STUB=0
if [[ "${1:-}" == "--stub" || "${1:-}" == "-Stub" ]]; then
  STUB=1
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--stub]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

REQUIRED=(
  onprem-jupyterhub:local
  onprem-jupyterlab-r440:local
  onprem-jupyterlab-r460:local
  onprem-rstudio-r440:local
  onprem-rstudio-r460:local
)

if [[ "$STUB" -eq 1 ]]; then
  echo "Building Hub image (onprem-jupyterhub:local)..."
  docker build -t onprem-jupyterhub:local \
    -f docker/jupyterhub/Dockerfile.hub docker/jupyterhub

  echo "Pulling jupyter/base-notebook (stub for all four spawn images)..."
  docker pull jupyter/base-notebook:latest

  for tag in \
    onprem-jupyterlab-r440:local \
    onprem-jupyterlab-r460:local \
    onprem-rstudio-r440:local \
    onprem-rstudio-r460:local
  do
    docker tag jupyter/base-notebook:latest "$tag"
    echo "Tagged stub $tag"
  done
else
  missing=()
  for tag in "${REQUIRED[@]}"; do
    if [[ -z "$(docker images -q "$tag")" ]]; then
      missing+=("$tag")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing local images:"
    printf '  %s\n' "${missing[@]}"
    echo
    echo "Build them from this repo first:"
    echo "  ./local-dev/build-images.sh"
    echo
    echo "Or start Hub UI only (not the real Lab/RStudio images):"
    echo "  ./local-dev/up.sh --stub"
    exit 1
  fi
fi

echo "Starting local Hub on http://localhost:8000 ..."
docker compose --env-file local-dev/.env -f local-dev/docker-compose.yml up -d

echo
echo "Hub is up:  http://localhost:8000"
echo "Login:      admin  /  password: test"
echo "            (any username works; password is DUMMY_PASSWORD in local-dev/.env)"
echo "Then start JupyterLab + R and/or RStudio from the Control Panel."
echo "Logs:       docker logs -f jupyterhub"
echo "Stop:       docker compose --env-file local-dev/.env -f local-dev/docker-compose.yml down"
